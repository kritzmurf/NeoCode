std = "luajit"
globals = {
    "vim",
}

files["tests/"] = {
    globals = { "MiniTest" },
}
