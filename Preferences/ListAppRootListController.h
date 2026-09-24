#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

@interface LABaseListController : PSListController
@property (nonatomic, strong) NSArray *cachedSpecifiers;
- (NSBundle *)bundle;
- (NSString *)plistName;
@end

@interface LARootListController : LABaseListController
@end

@interface LASubListController : LABaseListController
@end

@interface LAHeaderCell : PSTableCell
@end
