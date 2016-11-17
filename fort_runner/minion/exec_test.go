package minion

import (
	"testing"
	"time"
)

func TestBasicExec(t *testing.T) {
	cmd := &Cmd{
		Collect: true,
		Args:    []string{"ls"},
		Timeout: 10 * time.Second,
	}

	res := cmd.Exec()

	if res.Error != nil {
		t.Fail()
	}
}

func TestTimeout(t *testing.T) {
	cmd := &Cmd{
		Collect: true,
		Args:    []string{"sleep", "5"},
		Timeout: 1 * time.Second,
	}

	res := cmd.Exec()
	if res.Error == nil {
		t.Fail()
	}
}
