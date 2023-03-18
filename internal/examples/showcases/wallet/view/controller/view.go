package controller

import "github.com/bluszcz/cutego/core"

var Controller *viewController

type viewController struct {
	core.QObject

	_ func() `constructor:"init"`

	_ func(bool) `signal:"blur"`
}

func (c *viewController) init() {
	Controller = c
}
