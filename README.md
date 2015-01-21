# AOMultiproxier

[![Version](https://img.shields.io/cocoapods/v/AOMultiproxier.svg?style=flat)](http://cocoadocs.org/docsets/AOMultiproxier)
[![License](https://img.shields.io/cocoapods/l/AOMultiproxier.svg?style=flat)](http://cocoadocs.org/docsets/AOMultiproxier)
[![Platform](https://img.shields.io/cocoapods/p/AOMultiproxier.svg?style=flat)](http://cocoadocs.org/docsets/AOMultiproxier)

A simple proxy class that multiplexes and dispatches protocol methods to multiple objects.


## Installation

AOMultiproxier is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "AOMultiproxier"

## Example

In your header:

	@property (nonatomic, strong) UIScrollView * scrollView;
	@property (nonatomic, strong) id <UIScrollViewDelegate> scrollViewDelegateProxy;
	
In your init:

	self.scrollViewDelegateProxy = AOMultiproxierForProtocol(UIScrollViewDelegate);
	
	[self.scrollViewDelegateProxy attachObject:aDelegate];
	[self.scrollViewDelegateProxy attachObject:anotherDelegate];	
	
	self.scrollView.delegate = scrollViewDelegateProxy;

## Author

Alessandro Orrù, alessandro.orr@gmail.com, @alessandroorru on Twitter

## License

AOMultiproxier is available under the MIT license. See the LICENSE file for more info.
