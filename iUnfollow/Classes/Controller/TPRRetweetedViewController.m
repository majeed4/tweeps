//
//  TPRRetweetedViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 09/06/2013.
//
//

#import "TPRRetweetedViewController.h"
#import "TPRRetweetedProfileViewController.h"
#import "TPRUsersTableCell.h"

@interface TPRRetweetedViewController ()

@end

@implementation TPRRetweetedViewController

static NSString *cellIdentifier = @"TPRUsersTableViewCell";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.unfollowEnabled = NO;
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return self;
}

- (void)viewDidLoad
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewDidLoad];
    self.title = NSLocalizedString(@"Retweeted", nil);

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)viewWillAppear:(BOOL)animated
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewWillAppear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didFetchUserTweetsNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didUpdateFrienshipStatusNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didFetchUserDetailsNotifcation object:nil];
	[notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:deleteUsersFinished object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didSwitchAccountNotification object:nil];

    [self updateDataSource];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)viewDidAppear:(BOOL)animated
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewDidAppear:animated];

    if ([UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier)
    {
//        [[NetworkManager sharedInstance] updateUserTweets];
        [[NetworkManager sharedInstance] updateUserTweetsWithCompletionHandler:nil];
    }
    else
    {
        [Utils showPrevUserChangedAlert];
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)viewWillDisappear:(BOOL)animated
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewWillDisappear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:didFetchUserTweetsNotification object:nil];
    [notificationCenter removeObserver:self name:didUpdateFrienshipStatusNotification object:nil];
    [notificationCenter removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
	[notificationCenter removeObserver:self name:deleteUsersFinished object:nil];
    [notificationCenter removeObserver:self name:didSwitchAccountNotification object:nil];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)updateDataSource
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    self.items = [[DataManager sharedInstance] getAllRetweeted];
    self.items = [self.items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"userRetweets.@count" ascending:NO]]];
    if ([self.items count] > 20)
    {
        NSMutableArray *topUsers = [NSMutableArray array];
        for (NSInteger i = 0; i < 20; ++i)
        {
            [topUsers addObject:self.items[i]];
        }
        self.items = topUsers;
    }
    
    [super updateDataSource];

    [[self tableView] reloadData];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)setDataNeedsReload
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSource) object:nil];

	[self performSelector:@selector(updateDataSource) withObject:nil afterDelay:0.3];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (UITableViewCell *)tableView:(UITableView *)tableVieww
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TPRUsersTableCell *cell = [tableVieww dequeueReusableCellWithIdentifier:cellIdentifier];
    TwitterUser *user = (self.items)[indexPath.row];
    cell.loaded = user.hasDetails;
    cell.showRetweetCount = YES;
    cell.showDisclosureIndicator = YES;
    
    __weak TPRUsersTableCell *wcell = cell;
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.profileImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        wcell.imageView.image = [UIImage tpr_maskedImageWithImage:image];
        if (cacheType == SDImageCacheTypeNone) {
            wcell.imageView.alpha = 0.0;
            [UIView animateWithDuration:0.5 animations:^{
                wcell.imageView.alpha = 1.0;
            }];
        }
        [wcell setNeedsLayout];
    }];
//	[cell.imageView setImageWithURL:[NSURL URLWithString:user.profileImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        wcell.imageView.image = [UIImage tpr_maskedImageWithImage:image];
//        if (cacheType == SDImageCacheTypeNone) {
//            wcell.imageView.alpha = 0.0;
//            [UIView animateWithDuration:0.5 animations:^{
//                wcell.imageView.alpha = 1.0;
//            }];
//        }
//        [wcell setNeedsLayout];
//    }];
    
    cell.retweetsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)user.userRetweets.count];
    cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", user.screenName];
    cell.nameLabel.text = user.fullName;
    cell.followingLabel.text = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Following", nil), (long)user.numFollowing];
    cell.followersLabel.text = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Followers", nil), (long)user.numFollowers];
    
	return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TwitterUser *user = (self.items)[indexPath.row];
    if (!user.hasDetails)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
	}
    TPRRetweetedProfileViewController *vc = [[TPRRetweetedProfileViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:vc animated:YES];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

@end
