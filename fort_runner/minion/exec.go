package minion

import (
	"bufio"
	"fmt"
	"io"
	"os/exec"
	"time"
)

const logCmd = true

type CmdResult struct {
	Name   string        `json:"topic"`
	Cmd    []string      `json:"cmd"`
	Time   time.Duration `json:"time"`
	Output []string      `json:"output"`
	Error  error         `json:"error"`
}

type Cmd struct {
	Name    string
	Dir     string
	Env     []string
	Args    []string
	Timeout time.Duration
	Quit    chan struct{}
	Collect bool
}

func (c *Cmd) Exec() *CmdResult {
	t1 := time.Now()

	res := &CmdResult{
		Cmd:    c.Args,
		Output: []string{},
		Name:   c.Name,
	}

	cmd := exec.Command(c.Args[0], c.Args[1:]...)
	cmd.Dir = c.Dir

	if logCmd {
		fmt.Printf(">>> %s > %s", cmd.Dir, c.Args)
		defer func() {
			fmt.Printf(" -- %v\n", res.Time)
		}()
	}

	if c.Env != nil {
		cmd.Env = c.Env
	}

	done := make(chan struct{})
	defer close(done)

	if c.Timeout == 0 {
		c.Timeout = 5 * time.Second
	}

	go func() {
		select {
		case <-time.After(c.Timeout):
			cmd.Process.Kill()
			return
		case <-c.Quit:
			cmd.Process.Kill()
			return
		case <-done:
			return
		}
	}()

	if c.Collect {
		output := make(chan string)
		defer close(output)

		stdout, err := cmd.StdoutPipe()
		if err != nil {
			res.Error = err
			res.Time = time.Since(t1)
			return res
		}

		stderr, err := cmd.StderrPipe()
		if err != nil {
			res.Error = err
			res.Time = time.Since(t1)
			return res
		}

		go capture(output, stdout)
		go capture(output, stderr)

		go func() {
			for line := range output {
				res.Output = append(res.Output, line)
			}
		}()
	}

	err := cmd.Start()
	if err != nil {
		res.Error = err
		res.Time = time.Since(t1)
		return res
	}

	err = cmd.Wait()
	if err != nil {
		res.Error = err
		res.Time = time.Since(t1)
		return res
	}

	res.Time = time.Since(t1)
	return res
}

func capture(output chan string, std io.Reader) {
	buff := bufio.NewScanner(std)
	for buff.Scan() {
		select {
		case output <- buff.Text():
		default:
			return
		}
	}
}
