package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	hcl "github.com/hashicorp/hcl/v2"
	hclsyntax "github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

func readTfvars(path string) (map[string]any, error) {
	src, read_err := os.ReadFile(path)
	if read_err != nil {
		return nil, fmt.Errorf("Could not read the tfvars file! %v", read_err)
	}
	// reference: https://stackoverflow.com/a/78486469/31927360
	file, diags := hclsyntax.ParseConfig([]byte(src), "filename.tfvars", hcl.InitialPos)
	if diags.HasErrors() {
		return nil, fmt.Errorf("Could not parse tfvars vile! %v", diags)
	}

	attrs, diags := file.Body.JustAttributes()
	if diags.HasErrors() {
		return nil, fmt.Errorf("An error occurred while reading tfvars file! %v", read_err)
	}

	vals := make(map[string]any, len(attrs))
	for name, attr := range attrs {
		ctyval, diags := attr.Expr.Value(nil)
		if diags.HasErrors() {
			return nil, fmt.Errorf("Failed to parse tfvars file! %v", diags)
		}
		primval, ctyerrors := ctyValueToPrimitive(ctyval)
		if ctyerrors != nil {
			return nil, fmt.Errorf("Unexpected type encountered in tfvars file! %v", ctyerrors)
		}
		vals[name] = primval

	}
	return vals, nil
}

func ctyValueToPrimitive(val cty.Value) (any, error) {
	switch val.Type() {
	case cty.Number:
		return val.AsBigFloat(), nil
	case cty.String:
		return val.AsString(), nil
	case cty.Bool:
		return val.Equals(cty.True), nil
	default:
		return nil, fmt.Errorf("Unsupported type: %s", val.Type())
	}
}

func main() {
	// Get Terraform variables
	tfvars, tfvars_err := readTfvars("../../../terraform/credentials.auto.tfvars")
	if tfvars_err != nil {
		log.Fatalf("Could not read terraform variable file public key! %v", tfvars_err)
		return
	}
	// Create output file name from input file name
	out_base_name, found := strings.CutSuffix(filepath.Base(os.Args[1]), ".gotmpl")
	if !found {
		log.Fatalf("Input file name must end in .gotmpl! %v", os.Args[1])
		return
	}
	out_name := filepath.Join(filepath.Dir(os.Args[1]), out_base_name)
	cloudinit_template := template.New(filepath.Base(out_name))
	raw, err := os.ReadFile(os.Args[1])
	if err != nil {
		log.Fatalf("Could not read input %v", err)
		return
	}
	str := string(raw)
	cloudinit_template, parse_err := cloudinit_template.Parse(str)
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
	exec_err := cloudinit_template.Execute(writer, tfvars)
	writer.Flush()
	if exec_err != nil {
		log.Fatalf("Could not execute template! %v", exec_err)
	}
}
