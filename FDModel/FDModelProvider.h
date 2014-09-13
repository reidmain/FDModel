#import "FDModel.h"


#pragma mark Type Definitions

/**
This block is used to determine which FDModel subclass an object should be parsed into.

The majority of the time the value will be an NSDictionary object with NSString and NSValue being the next most common objects. NSDictionary is the most common because they are the objects that normally map one-to-one with a subclass of FDModel. Instances of NSString or NSValue usually reference an instance of an FDModel subclass that already exists in memory.
 
@param parentKey The key of a key-value pair within a NSDictionary if the object being parsed is an entry in a dictionary or if the entry in the dictionary is an array which contains the object being parsed.
@param value The object to be parsed.

@return Return a FDModel subclass if the value can be parsed into an instance of that subclass. Return nil if the value does not map to a FDModel subclass. Return NSNull if the value is 'invalid' or 'bad' in some way and should not be parsed at all.
*/
typedef Class (^FDModelProviderModelClassBlock)(NSString *parentKey, id value);


#pragma mark - Class Interface

/**
The FDModelProvider class encapsulates the transformation process from an object into an instance or collection of FDModel.

Any exceptions encountered during the setting of properties will be swallowed to ensure that incorrectly transformed objects cannot crash the application.

There are also a number of automatic transformations that the FDModelProvider performs:

1. If an NSString or NSValue is being set on a property whose type is FDModel and the model class block does not provide a class, an instance of FDModel whose identifier is the NSString or NSValue will automatically be created.
2. If an NSDictionary is being set on a property whose type is FDModel the dictionary is automatically attempted to be transformed into an instance of the FDModel.
3. If a NSString is being set on a property whose type is NSURL the string is automatically converted to a url.
4. If a NSString is being set on a property whose type is NSDate the string is automatically converted to a date using the model provider's date formatter.
5. If a NSNumber is being set on a property whose type is NSString the number is automatically converted to a string.
5. If a NSString is being set on a property whose type is NSNumber the string is automatically converted to a number.

Because the vast majority of FDModels being parsed in an application will occur in the same manor FDModelProvider exposes a shared instance that can be configured. This shared instance is used by FDModel internally. You can create your own instance of FDModelProvider if you would like but typically you should just configure the shared instance to ensure that all FDModel objects are parsed in the same manor regeradless of the method used to instantiate them.
*/
@interface FDModelProvider : NSObject


#pragma mark - Properties

/**
The data formatter to use whenever the model provider is attempting to set an instance of NSString on a property whose type is NSDate.
*/
@property (nonatomic, strong) NSDateFormatter *dateFormatter;


#pragma mark - Static Methods

+ (FDModelProvider *)sharedInstance;


#pragma mark - Instance Methods

/**
Attempts to transform the specified object into either an instance or collection of FDModel.

@param object The object to be transformed.
@param modelClassBlock The block to call when determining which class an object, encountered during the transformation process, should be parsed into. This parameter must not be nil.

@return Returns the transformed FDModel object. If the object cannot be transformed it will be returned.
*/
- (id)parseObject: (id)object 
	modelClassBlock: (FDModelProviderModelClassBlock)modelClassBlock;

@end