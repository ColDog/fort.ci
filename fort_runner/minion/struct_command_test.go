package minion

import (
	"fmt"
	"strings"
	"testing"
)

func TestBasicStruct(t *testing.T) {
	s := &struct {
		Dir   string `arg:"0"`
		Other string `arg:"1"`
		All   bool   `flag:"a"`
	}{".", "s", true}

	res := StructCommand(s, "ls")

	fmt.Printf("%v\n", res)
}

func TestStructCommand_Docker(t *testing.T) {
	d := &Docker{
		Name:  "db",
		Image: "mysql:5.7",
	}

	res := StructCommand(d, "docker", "run", "-d")

	if strings.Join(res, " ") == "docker run -d --name=db mysql:5.7" {
		t.Fatal(res)
	}
}
