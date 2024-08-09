public protocol T {}
public protocol P: T {}

public struct Foo: P {
	private struct Bar: T {
		public protocol Y {}
	}
}

public extension Foo.Bar.Y {
	var test: String { "hello" }
}

public extension Foo: Foo.Bar.Y {}