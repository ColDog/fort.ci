package minion

import (
	"testing"
)

func TestJob_Basic(t *testing.T) {
	j := &Job{
		Name: "list-files",
		ID:   "1.1",
		Sections: []*Section{
			{
				Name:      "list-files",
				Commands:  []string{"ls -a"},
				OnSuccess: []string{"echo 'ok'"},
				OnFailure: []string{"echo 'fail'"},
			},
		},
	}

	RunJob(j)
}

func TestJob_Clone(t *testing.T) {
	j := &Job{
		Name: "clone-job",
		ID:   "1.1",
		Repo: &Repo{
			Owner:    "coldog",
			Provider: "github.com",
			Name:     "radix-server",
			Commit:   "047516a",
		},
	}

	RunJob(j)
}

func TestJob_Fails(t *testing.T) {
	j := &Job{
		Name: "fail-job",
		ID:   "1.1",
		Sections: []*Section{
			{
				Name:      "fail",
				Commands:  []string{"exit 1"},
				OnSuccess: []string{"echo 'ok'"},
				OnFailure: []string{"echo 'fail'"},
			},
		},
	}

	r := RunJob(j)
	if r.Failure == nil {
		t.Fail()
	}
}

func TestJob_Services(t *testing.T) {
	j := &Job{
		Name: "services-job",
		ID:   "1.1",
		Sections: []*Section{
			{
				Name:      "list-files",
				Commands:  []string{"ls -a"},
				OnSuccess: []string{"echo 'ok'"},
				OnFailure: []string{"echo 'fail'"},
			},
		},
		Services: []*Service{
			{
				Name: "mysql",
				Docker: &Docker{
					Name:  "db",
					Image: "mysql:5.7",
				},
			},
		},
	}

	RunJob(j)
}

func TestJob_Builds(t *testing.T) {
	j := &Job{
		ID:   "1",
		Name: "services-job",
		Repo: &Repo{
			Owner:    "coldog",
			Provider: "github.com",
			Name:     "jenkins-job-test",
			Commit:   "93de9794c75ffee34218943011befd7a39f5b5b3",
		},
		Sections: []*Section{
			{
				Name:     "exec in docker",
				Commands: []string{"docker exec -i test-app bash -c 'echo hello'"},
			},
		},
		Builds: []*Build{
			{
				Name:       "test-app",
				Dockerfile: ".",
				Docker: &Docker{
					Cmd:       "bash",
					StdinOpen: true,
				},
			},
		},
		Services: []*Service{
			{
				Name: "mysql",
				Docker: &Docker{
					Name:  "db",
					Image: "mysql:5.7",
				},
			},
		},
	}

	run := RunJob(j)
	if run.Failure != nil {
		t.Fatal(run.Failure)
	}
}
