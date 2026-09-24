#import <UIKit/UIKit.h>
#import "ListAppModel.h"

@interface ListAppGridCell : UICollectionViewCell

@property (nonatomic, copy) void (^onTapHandler)(void);

- (void)configureWithItem:(ListAppItem *)item;

@end
