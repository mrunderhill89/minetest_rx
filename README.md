# MinetestRx
By Kevin "MrUnderhill89" Cameron

Summary: 
--
This mod adds [RxLua](https://github.com/bjornbytes/RxLua) (by Bjorn Swenson) and [Moses](https://github.com/Yonaba/Moses) (by Roland Yonaba) to [Minetest](http://www.minetest.net/),
and also wraps some of Minetest's existing API into Observables that can be used for more complex behavior. Because this is a utility mod, it is meant to be used with other mods and 
it doesn't add any new gameplay features by itself.

Libraries:
--
With the mod loaded, you use RxLua and Moses through `minetest.lib.Rx` and `minetest.lib._`, respectively. There is also my own library called "Deps" 
which was supposed to be a dependency manager, but I will probably remove it in the future unless I find a reason to keep it.

Observables:
--
MinetestRx adds new event hooks to Minetest's API and connects each one to an RxLua Observable. 
Observables are data structures that represent a stream of values that arrive over time. 
They are more flexible than callbacks in that they can be composed, split up, recombined, and reused for future events. 
Right now, only registration and player controls have observables, but I will add more if anyone needs them.

Extending Entities:
--
The current proof-of-concept for MinetestRx is the ability to extend registered data (like nodes, craftitems, etc.) as it comes in. 
For example, the following code adds a new "thread" group to Cotton from the farming mod. 

`
minetest.extend_craftitem("farming:cotton", {
    groups = {thread = 1}
})
`

Because this is an event-driven approach, we don't have to worry about whether, when, or how many times an item is defined: 
if it's never defined, the extension does nothing, and if we define it more than once (like if we have more than one farming mod), 
then the extension is run on each definition. You don't even have to worry about load order!

Player Input:
--
Observables can also be used to keep track of player input. Currently this is done using a data structure that splits input up by player, key, and event. 
This is still a work in progress right now, but eventually it should be able to do things like tell when a player is holding a button down instead of just 
pressing it, which could be useful for projectile mods.
