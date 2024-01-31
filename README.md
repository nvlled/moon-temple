# moon-temple
A small static site generator using lua DSL and [readbean](https://redbean.dev) runtime

# Code example
```lua
DIV {
    id="test-id",

    P {
        class = "ab cd efg",
        'this is a text',
        'this is another text',
        A { href = "index.html", "This is a link to the other page" }
    },

    BR,

    H1 "heading 1",
    H2 / A { href="/index.html", "heading 2 with link"},
    P / SPAN / "<span> inside <p>",

    P [[
    A block of text.
    A block of text.
    ]]

    STYLE {
        CSS '#test-id' {
            margin = "5px",
            border = "2px solid blue",
            color = "red",
            background_color = "#003",

            a = { 
                color = "white", 
                [":visited"] = { color = "gray", }
            },

            span = { color = "yellow" },
            [".ab"] = { color = "green" }
        }
    }
}
```

# Quick usage
1. clone this repo
```sh
git clone moon-temple
cd moon-temple
```

2. Run dev server
```sh
./moon-temple.com serve pages
```
3. open browser on http://localhost:8080

4. Build html files
```sh
# Ctrl-c twice to stop server
./moon-temple.com build pages/ output/
```

## Note on Ubuntu system
You might get an error saying **invalid CIL image**
on Ubuntu or other linux systems with binfmt service.
The error is due binfmt trying to guess how to run your 
binary executables, and in this case, it tries to 
use wine on the APE.

The fix, for me, is to just disable binfmt.
```sh
sudo systemctl disable binfmt-support
```

For other fixes, see installation section of the [redbean documentation](https://redbean.dev/).

# Installation
Either
- Put moon-temple.com on your bin/ path
- Put moon-temple.com on your project root directory

# Start new project
1. create project directory
```sh
mkdir new-site
```

2. create a sub folder to place your site content
```sh
cd new-site
mkdir pages/
```

4. create index.html.lua
```sh
cat <<EOF > pages > index.html.lua
return DIV {
    H1 "Hello world"
}
EOF
```

5. done

