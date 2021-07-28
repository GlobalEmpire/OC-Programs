# OpenTUI V1.0

OpenTUI - Open Text User Interface - is an OpenComputers Lua library that provides User Interface functionality.

## Design Principles

OpenTUI's design principles follow Ease of Implementation first, User Experience second, all else later. As such, all functions listed here are first and foremost incredibly simple to implement, often requiring only a single line of code to execute the function's entire portfolio, and are designed to to provide a visually clear layout to the user through its inherent simplicity on being a text based interface.

The downside is that this library is limited in customisability: Aside from the ability to change the displayed text when applicable and the colour of certain visual elements of the functions, the rest of the function is not customisable outside of the intended purpose of the function. This does however enforce consistency across programs that use this library, so it might end up being a boon, in the same way as how alt-key navigation hasn't changed because people know how to use it and it just works.

## Installation

Download a suitable version from the [official release](https://github.com/GlobalEmpire/OC-Programs/blob/master/Programs/OpenTUI/OpenTUI.lua) on github and drop it into any accepted package folder on a Lua Operating System (Like OpenOS). I recommend dropping it in /lib. To actually implement it in a program, all you need to do is to require the library, like this:

```lua
local OpenTUI = require("OpenTUI")
```

Much like any other library, the functions are directly available under the main assigned variable:

```lua
local VarList, SetDefault = OpenTUI.ParamList(VarList,...)
```

## Using my code in your projects

All I ask is that you credit me and my release on github, and that you contact me on discord (Tonatsi#8557) to tell me that you're using my program because I'll be really happy :D

## Common Variables

* ColourTable

This table allows you to specify the colours of different elements in functions in which it is passed as an argument. Think of it like CSS, except the blocks are sorted by attribute instead of element. You only need to specify the colour of elements you want to be different from the default values.

The name of the element in stored as the key and the colour is stored as the value, see the following example of a constructor for a valid table for the **BinaryChoice** function:

```lua
local ColourTable = {LeftTextColour=0xff0000,SelectionColour=0xe6db74}
```
As you can see, I only specified two of the four existing colour parameters. This means that these two will be changed, and the other two will stay default.
I will make it so that keys are not reused between programs unless they are the same element type, so that you can reuse a single Colour Table and keep a style between multiple functions, while the functions ignore keys for elements they do not possess.

## Functions

* **OpenTUI.Version**

**This isn't actually a function, it's a number, and as such you don't call it, but check its value** like any other variable. I would advise that any developer using this library check that the version number isn't inferior to the version they developed the program for. 

My goal is that these programs never break their previous implementations between updates, and as such I guarantee backwards compatibility to the fullest extent I can. Anything coded for one version of the program will always work in future versions, and I will only increase the version number if I have added a new function or more. 

Optimisations of functions will be re-implemented into previous versions under a new revision so that older versions still benefit. As such, if file space is a premium, you can get only the version that the program needs and nothing more, to cut down on space.

Furthermore, I will list the names of all in-file functions that any given function calls on, so advanced users can make a custom library removing every function they don't need. I would still advise keeping a version check for the minimum full library.

* **OpenTUI.ColourText(String,Colour)** 

This is the simplest function in the library. You provide a string and a colour hexcode and this program writes the string to the screen in that colour.

Technical description: This function is a wrapper for `term.write()`, except it changes the GPU Foreground colour before executing `term.write()`, and then does it again once it has written the string to set the foreground colour back to the previous colour. Don't forget to properly put spaces in either this function's string or the surrounding strings if you're putting this after and/or before a `term.write()`! Also, wrap is set to true here in `term.write()`.

* **OpenTUI.PrintLogo(String,ColourTable)** - *Requires OpenTUI.ColourText()*

This function writes to the center of the screen at the current Cursor Y value the provided string, surrounded in an ascii character box, if there is enough space. If not, it instead writes the String with fancy characters to the left and right. This only occurs if the screen is less than 3 character pixels tall.

This function recognises **`MainAccent`** and **`MainTextTheme`** as keys for `ColourTable`, **`MainAccent`** affects the colour of the box around the string and **`MainTextTheme`** affects the colour of the string itself. Both are white if not supplied. 
>**`MainAccent`** is ignored if the program writes the compact form.

Returns `false` if there's insufficient space (both horizontally or vertically) to print either of the forms.

Returns `true, 1` if the full form was written to the screen.

Returns `true, 2` if the compact form was written to the screen.

* **OpenTUI.BinaryChoice(LeftText,RightText,ColourTable,AllowAbbreviations)**

This function, when provided two strings, displays both strings on the left and right side of the screen from the center. The user can use the arrow keys to select which option they want and then press enter to confirm. If `AllowAbbreviations` is true and both strings start with unique letters, then the user will be able to instantly select and confirm an option by pressing the letter that corresponds to the first letter of the string of the option they want.

This function recognises **`LeftTextColour`**, **`RightTextColour`**, **`MainAccent`** and **`MainTextTheme`** as keys for `ColourTable`. **`LeftTextColour`** and **`RightTextColour`** determine the colour of their respective strings and are white by default, **`MainAccent`** determines the colour of the box that shows which option the user has selected and is white by default, and **`MainTextTheme`** determines the colour that the selection box becomes once the user has confirmed their selection and is green by default. 
>The function **does not clear itself** after it ends, you must clear the 3 previous lines of the screen yourself if you want to remove it.

Returns `false` if there was insufficient space on the screen.

Returns `true, 1` if the user selected the left option and `true, 2` if the user selected the right option.

* **OpenTUI.ParamList(ParamTable,ColourTable,VarSet,ReadOnly)** - *Requires OpenTUI.ColourText()*

This function allows a simple way to let the user modify a table directly; for example a configuration screen. 

`ParamTable`: This is the table that the program allows the user to edit. It displays this on screen, each key and its value one after the other. The table is directly modified, but is still returned by the function afterwards anyway.

`ColourTable`: This program recognises **`MainTextTheme`** and **`MainAccent`** as keys, **`MainTextTheme`** determines the colour of the keys when displayed and unsaved modified values, and **`MainAccent`** determines the colour of the line that is printed to separate the user's workspace and the key-value pairs of the table.

`VarSet`: This is a table that can optionally be provided. This allows you to restrict what the user can set as a variable for a given key, if a parameter can only accept a limited set of values. To use it, store an indexed table of the values you want to restrict the parameter to under the same key in `VarSet` as in `ParamTable`.

>For example, if you wanted to limit the values of a parameter stored under the key `config1` in `ParamTable` to choose between 'One', 'Two' and 'Three' then you would do:
```lua 
VarSet.config1={'One','Two','Three'}
```
>Now, the program will not allow the user to change the value of config1 if it does not exactly match these three terms. It will only do this for specified keys, any keys not specified here will have no restrictions.

`ReadOnly`: If `true`, the program will not allow the user to change any of the variables, and will instead immediately return once it has displayed the table. Useful for things like statistics readouts.