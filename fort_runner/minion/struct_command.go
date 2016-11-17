package minion

import (
	"fmt"
	"reflect"
	"strconv"
)

func StructCommand(item interface{}, main ...string) []string {
	args := []string{}
	flags := []string{}

	val := reflect.ValueOf(item).Elem()

	for i := 0; i < val.NumField(); i++ {
		tag := val.Type().Field(i).Tag
		value := val.Field(i).Interface()

		flag := tag.Get("flag")
		if flag != "" {
			switch value := value.(type) {
			case string:
				if value != "" {
					flags = append(flags, fmt.Sprintf("-%s=%s", flag, value))
				}
			case []string:
				for _, fval := range value {
					flags = append(flags, fmt.Sprintf("-%s=%s", flag, fval))
				}
			case bool:
				if value {
					flags = append(flags, fmt.Sprintf("-%s", flag))
				}
			default:
				flags = append(flags, fmt.Sprintf("-%s=%v", flag, value))
			}
		}

		arg := tag.Get("arg")
		if arg != "" {
			pos, err := strconv.Atoi(arg)
			if err != nil {
				panic(err)
			}

			// pad with blank strings
			for i := 0; i < pos; i++ {
				if i >= len(args) {
					args[i] = ""
				}
			}

			switch value := value.(type) {
			case string:
				args = append(args, value)
			case []string:
				args = append(args, value...)
			default:
				args = append(args, fmt.Sprintf("%v", value))
			}
		}
	}

	main = append(main, flags...)
	main = append(main, args...)
	return main
}
