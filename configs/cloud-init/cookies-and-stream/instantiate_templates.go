package main

import (
	"bufio"
	"bytes"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"text/template"
)

type User struct {
	Passwd             string
	SSH_authorized_key string
}

func main() {
	// Get publisc SSH key
	home_dir, homedir_err := os.UserHomeDir()
	if homedir_err != nil {
		log.Fatalf("Could not determine home directory! %v", homedir_err)
		return
	}
	ssh_pubkey := filepath.Join(home_dir, ".ssh/id_rsa.pub")
	ssh_key, ssh_key_err := os.ReadFile(ssh_pubkey)
	if ssh_key_err != nil {
		log.Fatalf("Could not read the SSH public key! %v", ssh_key_err)
		return
	}
	// Get password hash
	cmd := exec.Command("mkpasswd", "--method=SHA-512", "--rounds=500000")
	var outb, errb bytes.Buffer
	cmd.Stdout = &outb
	cmd.Stderr = &errb
	cmd_err := cmd.Run()
	if cmd_err != nil {
		log.Fatalf("Could not find mkpasswd command! %v", cmd_err)
		return
	}
	user := User{Passwd: strings.TrimSpace(outb.String()), SSH_authorized_key: strings.TrimSpace(string(ssh_key))}
	// Create output file name from input file name
	out_base_name, found := strings.CutSuffix(filepath.Base(os.Args[1]), ".gotmpl")
	if !found {
		log.Fatalf("Input file name must end in .gotmpl! %v", os.Args[1])
		return
	}
	out_name := filepath.Join(filepath.Dir(os.Args[1]), out_base_name)
	user_data_template := template.New("user-data")
	raw, err := os.ReadFile(os.Args[1])
	if err != nil {
		log.Fatalf("Could not read input %v", err)
		return
	}
	str := string(raw)
	user_data_template, parse_err := user_data_template.Parse(str)
	if parse_err != nil {
		log.Fatalf("Could not parse template! %v", parse_err)
		return
	}
	fd, create_err := os.Create(out_name)
	if create_err != nil {
		log.Fatalf("Could not create output file! %v", create_err)
		return
	}
	writer := bufio.NewWriter(fd)
	exec_err := user_data_template.Execute(writer, user)
	writer.Flush()
	if exec_err != nil {
		log.Fatalf("Could not execute template! %v", exec_err)
	}
}
