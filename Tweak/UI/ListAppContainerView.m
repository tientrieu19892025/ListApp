#import "ListAppContainerView.h"
#import "ListAppGridCell.h"
#import "ListAppModel.h"
#import "ListAppPrefs.h"
#import "ListAppSafety.h"
#import "ListAppConstants.h"
#import <QuartzCore/QuartzCore.h>

@interface ListAppContainerView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@end

@implementation ListAppContainerView {
    UIView *_searchPillView;
    UIVisualEffectView *_searchBlurView;
    UIView *_searchTintView;
    CALayer *_searchBorder;
    UITextField *_searchField;
    UICollectionView *_collectionView;
    UICollectionViewFlowLayout *_flowLayout;
    NSArray<ListAppItem *> *_displayedApps;
    NSString *_searchQuery;
    UIImpactFeedbackGenerator *_feedbackGen;
}

+ (instancetype)sharedView {
    static ListAppContainerView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        instance = [[ListAppContainerView alloc] initWithFrame:screenBounds];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (CGRectIsEmpty(frame) || frame.size.width < 50 || frame.size.height < 50) {
        frame = [UIScreen mainScreen].bounds;
    }

    self = [super initWithFrame:frame];
    if (!self) return self;

    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _displayedApps = @[];
    _searchQuery = @"";
    _feedbackGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];

    // 1. Search Bar 2/3 width liquid glass pill
    _searchPillView = [[UIView alloc] initWithFrame:CGRectZero];
    _searchPillView.backgroundColor = [UIColor clearColor];
    _searchPillView.clipsToBounds = YES;
    _searchPillView.layer.cornerRadius = 18.0;
    if (@available(iOS 13.0, *)) {
        _searchPillView.layer.cornerCurve = kCACornerCurveContinuous;
    }

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
    _searchBlurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    _searchBlurView.userInteractionEnabled = NO;
    [_searchPillView addSubview:_searchBlurView];

    _searchTintView = [[UIView alloc] initWithFrame:CGRectZero];
    _searchTintView.userInteractionEnabled = NO;
    _searchTintView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14];
    [_searchPillView addSubview:_searchTintView];

    _searchBorder = [CALayer layer];
    _searchBorder.cornerRadius = 18.0;
    _searchBorder.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35].CGColor;
    _searchBorder.borderWidth = 1.0 / MAX([UIScreen mainScreen].scale, 2.0);
    if (@available(iOS 13.0, *)) {
        _searchBorder.cornerCurve = kCACornerCurveContinuous;
    }
    [_searchPillView.layer addSublayer:_searchBorder];

    _searchField = [[UITextField alloc] initWithFrame:CGRectZero];
    _searchField.placeholder = @"Search apps...";
    _searchField.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _searchField.textColor = [UIColor whiteColor];
    _searchField.tintColor = [UIColor whiteColor];
    _searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _searchField.autocorrectionType = UITextAutocorrectionTypeNo;
    _searchField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchField.returnKeyType = UIReturnKeyDone;
    _searchField.delegate = self;
    [_searchField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];

    if (@available(iOS 13.0, *)) {
        UIImage *searchIcon = [UIImage systemImageNamed:@"magnifyingglass"];
        UIImageView *iconView = [[UIImageView alloc] initWithImage:searchIcon];
        iconView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.65];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.frame = CGRectMake(12, 0, 18, 18);

        UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 18)];
        [leftPad addSubview:iconView];
        _searchField.leftView = leftPad;
        _searchField.leftViewMode = UITextFieldViewModeAlways;
    }
    [_searchPillView addSubview:_searchField];
    [self addSubview:_searchPillView];

    // 2. Collection View of elongated liquid glass rows
    _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    _flowLayout.minimumInteritemSpacing = 0.0;
    _flowLayout.minimumLineSpacing = 2.0;

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_flowLayout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.delaysContentTouches = NO;
    _collectionView.canCancelContentTouches = YES;
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [_collectionView registerClass:[ListAppGridCell class] forCellWithReuseIdentifier:@"ListAppGridCell"];
    [self addSubview:_collectionView];

    return self;
}

- (void)applyConfiguration {
    BOOL showSearch = [ListAppPrefs showSearchBar];
    _searchPillView.hidden = !showSearch;

    [[ListAppModel sharedInstance] clearIconCache];
    [_flowLayout invalidateLayout];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [_collectionView reloadData];
}

- (void)reloadApps {
    [[ListAppModel sharedInstance] loadInstalledApplicationsWithCompletion:^(NSArray<ListAppItem *> *apps) {
        [self filterAndRefresh];
    }];
}

- (void)filterAndRefresh {
    if (_searchQuery.length > 0) {
        _displayedApps = [[ListAppModel sharedInstance] filteredAppsWithQuery:_searchQuery];
    } else {
        _displayedApps = [[ListAppModel sharedInstance] allItems];
    }
    [_collectionView reloadData];
}

- (void)searchTextChanged:(UITextField *)tf {
    _searchQuery = tf.text ?: @"";
    [self filterAndRefresh];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    if (width <= 0 || height <= 0) return;

    CGFloat topSafeArea = 54.0;
    if (@available(iOS 11.0, *)) {
        if (self.safeAreaInsets.top > 0) {
            topSafeArea = self.safeAreaInsets.top + 6.0;
        }
    }

    CGFloat bottomSafeArea = 34.0;
    if (@available(iOS 11.0, *)) {
        if (self.safeAreaInsets.bottom > 0) {
            bottomSafeArea = self.safeAreaInsets.bottom;
        }
    }

    CGFloat topY = topSafeArea;

    if ([ListAppPrefs showSearchBar]) {
        CGFloat searchW = floor(width * (2.0 / 3.0));
        CGFloat searchX = floor((width - searchW) / 2.0);
        CGFloat searchH = 40.0;
        _searchPillView.frame = CGRectMake(searchX, topY, searchW, searchH);
        _searchBlurView.frame = _searchPillView.bounds;
        _searchTintView.frame = _searchPillView.bounds;
        _searchBorder.frame = _searchPillView.bounds;
        _searchField.frame = _searchPillView.bounds;
        topY = CGRectGetMaxY(_searchPillView.frame) + 12.0;
    } else {
        _searchPillView.frame = CGRectZero;
        topY = topSafeArea + 8.0;
    }

    _collectionView.frame = CGRectMake(0, topY, width, height - topY - bottomSafeArea);
    _flowLayout.sectionInset = UIEdgeInsetsMake(6, 0, 24, 0);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _displayedApps.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ListAppGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ListAppGridCell" forIndexPath:indexPath];
    if (indexPath.item < _displayedApps.count) {
        ListAppItem *item = _displayedApps[indexPath.item];
        [cell configureWithItem:item];
        __weak typeof(self) weakSelf = self;
        cell.onTapHandler = ^{
            [weakSelf launchItem:item];
        };
    }
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalW = collectionView.bounds.size.width;
    if (totalW <= 50.0) {
        totalW = [UIScreen mainScreen].bounds.size.width;
    }
    CGFloat iconSz = [ListAppPrefs iconSize];
    CGFloat cellHeight = MAX(64.0, iconSz + 16.0);
    return CGSizeMake(totalW, cellHeight);
}

- (void)launchItem:(ListAppItem *)item {
    if (!item) return;

    static NSTimeInterval sLastLaunchTime = 0;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - sLastLaunchTime < 0.35) return;
    sLastLaunchTime = now;

    if ([ListAppPrefs haptics]) {
        [_feedbackGen impactOccurred];
    }

    [_searchField resignFirstResponder];
    [[ListAppModel sharedInstance] launchApp:item];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= _displayedApps.count) return;
    ListAppItem *item = _displayedApps[indexPath.item];
    [self launchItem:item];
}

@end
