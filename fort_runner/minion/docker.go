package minion

type Docker struct {
	Image      string   `json:"image" arg:"0"`
	Name       string   `json:"name" flag:"-name"`
	Cmd        string   `json:"cmd" arg:"1"`
	EntryPoint string   `json:"entryPoint" flag:"-entrypoint"`
	Ports      []string `json:"ports" flag:"p"`
	Net        string   `json:"ports" flag:"-network"`
	NetAlias   string   `json:"netAlias" flag:"-network-alias"`
	Env        []string `json:"env" flag:"e"`
	WorkDir    string   `json:"workDir" flag:"-workdir"`
	TTY        bool     `json:"tty" flag:"t"`
	StdinOpen  bool     `json:"stdinOpen" flag:"i"`
}

func (d *Docker) Run() *CmdResult {
	args := StructCommand(d, "docker", "run", "-d")

	c := Cmd{
		Args:    args,
		Collect: true,
	}

	return c.Exec()
}
