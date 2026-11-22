package com.dicek.app

actual fun platformName(): String =
    "Desktop · ${System.getProperty("os.name")} ${System.getProperty("os.version")}"
