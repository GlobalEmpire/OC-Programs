# OpenTUI V1.0

OpenTUI - Open Text User Interface - is an OpenComputers Lua library that provides User Interface functionality.

## Design Principles

OpenTUI's design principles follow Ease of Implementation first, User Experience second, all else later. As such, all functions listed here are first and foremost incredibly simple to implement, often requiring only a single line of code to execute the function's entire portfolio, and are designed to to provide a visually clear layout to the user through its inherent simplicity on being a text based interface.

The downside is that this library is limited in customisability: Aside from the ability to change the displayed text when applicable and the colour of certain visual elements of the functions, the rest of the function is not customisable outside of the intended purpose of the function. This does however enforce consistency across programs that use this library, so it might end up being a boon, in the same way as how alt-key navigation hasn't changed because people know how to use it and it just works.

## Installation

Download a suitable version from the [official release](https://github.com/GlobalEmpire/OC-Programs/blob/master/Programs/OpenTUI/OpenTUI.lua) on github and drop it into any accepted package folder on a Lua Operating System (Like OpenOS). I recommend dropping in /lib. To actually implement it in a program, all that you need is to require the library, like this:

```lua
local OpenTUI = require("OpenTUI")
```