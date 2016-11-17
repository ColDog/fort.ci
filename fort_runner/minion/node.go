package minion

import "os"

var rootDir string

func init() {
	if os.Getenv("CI_ROOT_DIR") != "" {
		rootDir = os.Getenv("CI_ROOT_DIR")
	}

	if rootDir == "" {
		var err error
		rootDir, err = os.Getwd()
		if err != nil {
			panic(err)
		}
	}

	os.Mkdir("./workspace", 0700)
	os.Mkdir("./jobs", 0700)
}
