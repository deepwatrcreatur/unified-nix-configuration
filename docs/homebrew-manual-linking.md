# Manual Homebrew Ruby Symlink

## The Problem

When installing Homebrew on NixOS, you may encounter a `ln: command not found` error, which leads to a `ruby: No such file or directory` error. This is because the Homebrew installation script is run in a minimal environment with a very limited `PATH`, and it is not able to find the `ln` command.

## The Solution

To fix this, you need to manually create a symlink from the `current` directory to the actual Ruby version that Homebrew has downloaded.

## Instructions

1.  **Open a terminal**

2.  **Run the following command:**

    ```bash
    sudo ln -s /home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/vendor/portable-ruby/3.4.5 /home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/vendor/portable-ruby/current
    ```

3.  **Activate your NixOS configuration again.**

This will create the necessary symlink and allow the Homebrew installation to complete successfully.
