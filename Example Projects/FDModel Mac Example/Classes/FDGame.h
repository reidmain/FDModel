#pragma mark Class Interface

@interface FDGame : FDModel


#pragma mark - Properties

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *platform;
@property (nonatomic, copy) NSDate *releaseDate;


@end