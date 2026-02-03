package main

import (
	"log"
	"os"
	"text/template"
)

type User struct {
	Passwd             string
	SSH_authorized_key string
}

func main() {
	user := User{Passwd: "test", SSH_authorized_key: "test"}
	t1 := template.New("t1")
	raw, err := os.ReadFile(os.Args[1])
	if err != nil {
		log.Fatalf("Could not read input %v", err)
		return
	}
	str := string(raw)
	println(str)
	t1, parse_err := t1.Parse(str)
	if parse_err != nil {
		log.Fatalf("Could not parse template! %v", parse_err)
		return
	}
	exec_err := t1.Execute(os.Stdout, user)
	if exec_err != nil {
		log.Fatalf("Could not execute template! %v", exec_err)
	}
	println("Foo")
}
