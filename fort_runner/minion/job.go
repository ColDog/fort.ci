package minion

import "fmt"

type Job struct {
	ID       string     `json:"id"`
	Repo     *Repo      `json:"repo"`
	Builds   []*Build   `json:"builds"`
	Services []*Service `json:"services"`
	Sections []*Section `json:"sections"`
	Env      []string   `json:"env"`
}

type Repo struct {
	Owner    string `json:"owner"`
	Name     string `json:"name"`
	Provider string `json:"provider"`
	Token    string `json:"token"`
	Commit   string `json:"commit"`
}

func (r *Repo) URL() string {
	return fmt.Sprintf("https://%s@%s/%s/%s", r.Token, r.Provider, r.Owner, r.Name)
}

type Section struct {
	RunOnFailure bool     `json:"run_on_failure"`
	RunAllCmds   bool     `json:"run_all_cmds"`
	Name         string   `json:"name"`
	Commands     []string `json:"commands"`
	OnSuccess    []string `json:"on_success"`
	OnFailure    []string `json:"on_failure"`
}

type Service struct {
	Name   string   `json:"name"`
	Docker *Docker  `json:"docker"`
	After  []string `json:"after"`
	Before []string `json:"before"`
}

type Build struct {
	Name       string   `json:"name"`
	Dockerfile string   `json:"dockerfile"`
	BuildArgs  []string `json:"args"`
	Docker     *Docker  `json:"docker"`
	After      []string `json:"after"`
	Before     []string `json:"before"`
}
