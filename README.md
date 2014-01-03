# KissNSUbiquitousKeyValueStore

Keep it simple, stupid!

Directly hard code to access keys of `NSUbiquitousKeyValueStore` is very boring.

if we can access keys via properties and listen to the specific `NSUbiquitousKeyValueStore` key change, life must be more easier.

This is what `KissNSUbiquitousKeyValueStore` project borns to be. What you need to do is to declare properties in header and `@dynamic` all in implementation. Run `+kiss_setup` or `+kiss_setupWithCustomKeys:` in `+load` will generate all accessors for you. 

## Usage

Add `NSUbiquitousKeyValueStore+Kiss.h` and `NSUbiquitousKeyValueStore+Kiss.m` to your project. Make your own `NSUbiquitousKeyValueStore` category, import `NSUbiquitousKeyValueStore+KissNSUbiquitousKeyValueStore.h` and run `+kiss_setup` in your category's `+load`. If you need to transit old keys, or need to keep key and property in its own name, you can run `+kiss_setupWithCustomKeys:` with your own key-property pairs dictionary.
		
## Creator

* GitHub: <https://github.com/cxa>
* Twitter: [@_cxa](https://twitter.com/_cxa)
* Apps available in App Store: <http://lazyapps.com>

## License

Under the MIT license. See the LICENSE file for more information.