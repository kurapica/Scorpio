# Scorpio

The Scorpio Project is used to build an addon platform for World of Warcraft.

It's designed based on the [PLoop](https://github.com/kurapica/PLoop_WOW), although the Lib is created based on
the OOP system, it provided a pure functional programming style to easy the addon development. 

The Scorpio provides several features to simple and power the addons:

1. A declarative functional programming style to register and handle the system events, secure hooks and slash commands.

2. A full addon life-cycle management. Addons can split their features into several modules for management.

3. An asynchronous framework to avoid the using of callbacks, and have all the asynchronous tasks controlled under
a task schedule system, so the FPS will be smooth and almost no dropping caused by the Lua codes.

4. A new UI & Skin system, It'll split the functionality and display of the widgets, so we can create functionality 
UIs in one addons, and let's other authors do the skin parts very easily.

5. ~~A well designed secure template framework, so we can enjoy the power of the secure template system provided by 
the blizzard and stay away the hard part. (coming soon)~~

## Preparation

The Scorpio Lib require the [PLoop](https://github.com/kurapica/PLoop_WOW), both can be download through the curseforge:

* [PLoop](https://www.curseforge.com/wow/addons/ploop)
* [Scorpio](https://www.curseforge.com/wow/addons/scorpio)

The Scorpio Lib is separated to several folders, so the features can be loaded on demand.

* Scorpio - The core system, provide the declarative functional programming style, the addon management and the 
    asynchronous framework, all for the non-ui part.

* Scorpio.UI - The ui core system, provide the new template and skin system, provide the basic features like enums,
    structs and basic widget classes.

* Scorpio.Widget - The common widget classes and helpful APIs to simple the user interaction.

## Documents

You can find the documents for each parts:

* [Addon & The Declarative Functional Programming](https://github.com/kurapica/Scorpio/blob/master/Docs/001.addon.md)
* [Asynchronous Framework & Task Schedule System](https://github.com/kurapica/Scorpio/blob/master/Docs/002.async.md)
* [The basic UI Template & Skin System](https://github.com/kurapica/Scorpio/blob/master/Docs/003.ui.md)
* [The Common Widgets](https://github.com/kurapica/Scorpio/blob/master/Docs/004.widget.md)