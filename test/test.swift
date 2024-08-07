protocol T {}
protocol P: T {}

struct Foo: P {
	struct Bar: T {
		protocol Y {}
	}
}

extension Foo.Bar.Y {
	var test: String { "hello" }
}

extension Foo: Foo.Bar.Y {}