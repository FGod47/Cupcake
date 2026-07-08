local HOME = os.getenv("HOME")

hl.monitor({
    output = "DP-1",
    mode = "1920x1080@164.998",
    position = "0x0",
    scale = 1.0
})

hl.monitor({
    output = "",
    mode = "highrr",
    position = "auto",
    scale = 1
})
