package minion

import (
	"fmt"
	"os"
	"strings"
	"time"
)

type Stage func() error

type Run struct {
	Job       *Job         `json:"job"`
	Results   []*CmdResult `json:"results"`
	Failure   error        `json:"failure"`
	Cancelled bool         `json:"cancelled"`
	Workspace string       `json:"workspace"`
	env       []string
	section   string
	quit      chan struct{}
}

func NewRunner(j *Job) *Run {
	return &Run{
		Job:     j,
		Results: []*CmdResult{},
		quit:    make(chan struct{}),
	}
}

func RunJob(j *Job) *Run {
	r := NewRunner(j)
	r.Run()
	return r
}

func (r *Run) setSection(name string) {
	r.section = name
}

func (r *Run) Quit() {
	r.Cancelled = true
	close(r.quit)
}

func (r *Run) exec(args ...string) error {
	if r.Cancelled {
		return fmt.Errorf("cancelled")
	}

	c := &Cmd{
		Name:    r.section,
		Args:    args,
		Collect: true,
		Quit:    r.quit,
		Dir:     r.Workspace,
		Env:     r.env,
	}

	res := c.Exec()
	r.Results = append(r.Results, res)

	return res.Error
}

func (r *Run) execAll(cmds []string) error {
	for _, cmd := range cmds {
		err := r.exec("sh", "-c", cmd)
		if err != nil {
			return err
		}
	}
	return nil
}

func (r *Run) execAllFully(cmds []string) (err error) {
	for _, cmd := range cmds {
		err = r.exec("sh", "-c", cmd)
	}
	return err
}

func (r *Run) initialize() error {
	if r.Job.ID == "" {
		r.Job.ID = fmt.Sprintf("%v", time.Now().UnixNano())
	}

	if r.Job.Repo.Provider == "github" {
		r.Job.Repo.Provider = "github.com"
	}

	if r.Job.Repo.Provider == "bitbucket" {
		r.Job.Repo.Provider = "bitbucket.org"
	}

	r.env = os.Environ()
	r.env = append(r.env,
		"CI=true",
		envVar("CI_JOB_ID", r.Job.ID),
		envVar("CI_JOB_URL", "todo"),
		envVar("CI_JOB_URL", "todo"),
	)

	return nil
}

func (r *Run) initializeRepo() error {
	r.setSection("git-sync")

	var err error

	if r.Job.Repo == nil {
		return nil
	}

	// validate repo
	if r.Job.Repo.Name == "" || r.Job.Repo.Commit == "" || r.Job.Repo.Owner == "" {
		return fmt.Errorf("invalid repo %+v", r.Job.Repo)
	}

	// set up the workspace
	if _, err = os.Stat("workspace/" + r.Job.Repo.Name); os.IsNotExist(err) {
		err = r.exec("git", "clone", r.Job.Repo.URL(), "./workspace/"+r.Job.Repo.Name)
		if err != nil {
			return err
		}

		r.Workspace = rootDir + "/workspace/" + r.Job.Repo.Name
	} else {
		r.Workspace = rootDir + "/workspace/" + r.Job.Repo.Name
		err = r.exec("git", "fetch")
		if err != nil {
			return err
		}
	}

	err = r.exec("git", "checkout", r.Job.Repo.Commit)
	if err != nil {
		return err
	}

	// get the author of this commit
	r.exec("git", "show", "--quiet", "--format=%ae", r.Job.Repo.Commit)
	author := r.Results[len(r.Results)-1].Output[0]

	// get current branch
	r.exec("git", "rev-parse", "--abbrev-ref", "HEAD")
	branch := r.Results[len(r.Results)-1].Output[0]

	// add git environment variable
	r.env = append(r.env,
		envVar("CI_GIT_REPO", r.Job.Repo.Name),
		envVar("CI_GIT_OWNER", r.Job.Repo.Owner),
		envVar("CI_GIT_BRANCH", branch),
		envVar("CI_GIT_COMMIT", r.Job.Repo.Commit),
		envVar("CI_GIT_COMMIT_AUTHOR", author),
		envVar("CI_BUILD_KEY", strings.Replace(fmt.Sprintf("%s.%d", branch, r.Job.ID), "/", "_", -1)),
	)

	r.exec("ls", "-a")

	return nil
}

func (r *Run) startServices() error {
	r.setSection("services")
	r.exec("docker", "network", "create", r.Job.ID)

	for _, service := range r.Job.Services {
		if r.Cancelled {
			return nil
		}

		// if no image, log this as a failure
		if service.Docker.Image == "" || service.Docker == nil {
			return fmt.Errorf("no image to start")
		}

		// ensure the service has a name.
		if service.Name == "" && service.Docker.Name != "" {
			service.Name = service.Docker.Name
		} else {
			service.Name = strings.Split(service.Docker.Image, ":")[0]
			service.Docker.Name = service.Name
		}

		// create a unique name for the section.
		name := "services/" + service.Name
		r.setSection(name)

		// add some variables
		service.Docker.Net = r.Job.ID
		service.Docker.NetAlias = service.Docker.Name

		// execute the before scripts
		r.execAll(service.Before)

		// start the service
		res := service.Docker.Run()
		res.Name = name
		r.Results = append(r.Results, res)

		if res.Error != nil {
			return res.Error
		}

		r.execAll(service.After)
	}

	return nil
}

func (r *Run) setupBuilds() error {
	for id, build := range r.Job.Builds {
		if r.Cancelled {
			return nil
		}

		// the build is a description of a service that has a dockerfile to be built before.
		if build.Name == "" {
			if id > 0 {
				build.Name = fmt.Sprintf("app-%d", id)
			} else {
				build.Name = "app"
			}
		}

		name := "builds/" + build.Name
		r.setSection(name)

		// set up the various required elements
		if build.Dockerfile == "" {
			build.Dockerfile = "."
		}

		if build.Docker == nil {
			build.Docker = &Docker{}
		}

		// set the docker image with some values, we keep the name the same across all pieces.
		build.Docker.Name = build.Name
		build.Docker.NetAlias = build.Docker.Name
		build.Docker.Net = r.Job.ID
		build.Docker.Image = build.Name

		cmd := []string{"docker", "build", "-t", build.Name}
		cmd = append(cmd, build.BuildArgs...)
		cmd = append(cmd, build.Dockerfile)

		err := r.exec(cmd...)
		if err != nil {
			return err
		}

		// start the build
		res := build.Docker.Run()
		res.Name = name
		r.Results = append(r.Results, res)

		// fail the job if this fails
		if res.Error != nil {
			return res.Error
		}
	}

	return nil
}

func (r *Run) runSections() (err error) {
	err = r.Failure

	for id, section := range r.Job.Sections {
		if r.Cancelled {
			return nil
		}

		if section.Name == "" {
			section.Name = fmt.Sprintf("section-%d", id)
		}

		r.setSection("sections/" + section.Name)

		if err != nil && !section.RunOnFailure {
			continue
		}

		if section.RunAllCmds {
			err = r.execAllFully(section.Commands)
		} else {
			err = r.execAll(section.Commands)
		}

		if err == nil {
			r.execAllFully(section.OnSuccess)
		} else {
			r.execAllFully(section.OnFailure)
		}

		if r.Failure == nil {
			r.Failure = err
		}
	}

	return err
}

func (r *Run) cleanup() error {
	r.setSection("cleanup")

	for _, service := range r.Job.Services {
		r.exec("docker", "rm", "-f", service.Docker.Name)
	}

	for _, build := range r.Job.Builds {
		r.exec("docker", "rm", "-f", build.Docker.Name)
	}

	r.exec("docker", "network", "rm", r.Job.ID)
	return nil
}

func (r *Run) runner(stages, ensure, cleanup []Stage) {
	for _, stage := range stages {
		if r.Cancelled {
			break
		}

		err := stage()
		if err != nil {
			r.Failure = err
			break
		}
	}

	for _, stage := range ensure {
		if r.Cancelled {
			break
		}
		stage()
	}

	for _, stage := range cleanup {
		stage()
	}
}

func (r *Run) Run() {
	r.runner(
		//
		[]Stage{
			r.initialize,
			r.initializeRepo,
			r.startServices,
			r.setupBuilds,
		},

		// ensure this section is run normally
		[]Stage{
			r.runSections,
		},

		// cleanup sections
		[]Stage{
			r.cleanup,
		},
	)
}

func envVar(variable string, value interface{}) string {
	return fmt.Sprintf("%s=%v", variable, value)
}
