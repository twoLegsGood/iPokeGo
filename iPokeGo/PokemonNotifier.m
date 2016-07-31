//
//  PokemonNotifier.m
//  iPokeGo
//
//  Created by Curtis herbert on 7/30/16.
//  Copyright © 2016 Dimitri Dessus. All rights reserved.
//

@import CoreData;
#import "PokemonNotifier.h"
#import "CoreDataEntities.h"
#import "MapViewController.h"
#import "CoreDataPersistance.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>
#import "CWStatusBarNotification.h"
#import "SettingsTableViewController.h"

@interface PokemonNotifier() <NSFetchedResultsControllerDelegate>

@property NSFetchedResultsController *pokemonFetchResultsController;
@property AVAudioPlayer *pokemonAppearSound;
@property AVAudioPlayer *pokemonFavAppearSound;
@property BOOL incomingIsFromNewConnection;
@property NSDictionary *localization;

@end

@implementation PokemonNotifier

- (instancetype)init {
    if (self = [super init]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Pokemon"];
        [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"encounter" ascending:YES]]];
        NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[CoreDataPersistance sharedInstance].uiContext sectionNameKeyPath:nil cacheName:nil];
        frc.delegate = self;
        NSError *error = nil;
        if (![frc performFetch:&error]) {
            NSLog(@"Error performing fetch request for pokemon notification listener: %@", error);
        }
        self.pokemonFetchResultsController = frc;
        
        NSString *pathPokemonAppearSound    = [NSString stringWithFormat:@"%@/ding.mp3", [[NSBundle mainBundle] resourcePath]];
        NSURL *soundUrlPokemonAppearSound   = [NSURL fileURLWithPath:pathPokemonAppearSound];
        
        NSString *pathPokemonFavAppearSound    = [NSString stringWithFormat:@"%@/favoritePokemon.mp3", [[NSBundle mainBundle] resourcePath]];
        NSURL *soundUrlPokemonFavAppearSound   = [NSURL fileURLWithPath:pathPokemonFavAppearSound];
        
        AVAudioSession *audiosession = [AVAudioSession sharedInstance];
        [audiosession setCategory:AVAudioSessionCategoryAmbient error:nil];
        
        self.pokemonAppearSound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrlPokemonAppearSound error:nil];
        self.pokemonFavAppearSound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrlPokemonFavAppearSound error:nil];
        
        //we want to hide notifications for normal pokemon in two conditions:
        //if they've changed the server address, or if this is the first connection in a long time
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverChanged) name:ServerChangedNotification object:nil];
        self.incomingIsFromNewConnection = YES;
        
        [self loadLocalization];
    }
    return self;
}

-(void)loadLocalization {
    NSError *error;
    
    NSURL *filePath = [[NSBundle mainBundle] URLForResource:@"pokemon" withExtension:@"json"];
    
    self.localization = [[NSDictionary alloc] init];
    
    NSString *stringPath = [filePath absoluteString];
    NSData *localizationData = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
    
    self.localization = [NSJSONSerialization JSONObjectWithData:localizationData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
}

-(void)displayNotificationForPokemon:(Pokemon *)pokemon
{
    NSString *message   = nil;
    AVAudioPlayer *sound = nil;
    
    if([pokemon isFav]) {
        message = [NSString localizedStringWithFormat:NSLocalizedString(@"[Pokemon] your favorite pokemon was added to the map!", @"The hint that a favorite Pokémon appeared on the map.") , [self.localization objectForKey:[NSString stringWithFormat:@"%d", pokemon.identifier]]];
        sound   = self.pokemonAppearSound;
    } else {
        message = [NSString localizedStringWithFormat:NSLocalizedString(@"[Pokemon] was added to the map!", @"The hint that a certain Pokémon appeared on the map.") , [self.localization objectForKey:[NSString stringWithFormat:@"%d", pokemon.identifier]]];
        sound   = self.pokemonAppearSound;
    }
    
    //creating a region to zoom on the pokemon
    MKCoordinateRegion region;
    region.center = pokemon.location;
    region.span.latitudeDelta   = MAP_SCALE_ANNOT;
    region.span.longitudeDelta  = MAP_SCALE_ANNOT;
    
    //pre iOS 10 notifications aren't shown when the app is active, so only show them in BG
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        NSDictionary *infoDict = [NSDictionary dictionaryWithObjects:@[@(pokemon.location.latitude), @(pokemon.location.longitude)] forKeys:@[@"latitude", @"longitude"]];
        
        UILocalNotification *localN         = [[UILocalNotification alloc] init];
        localN.fireDate                     = [NSDate date];
        localN.alertBody                    = message;
        localN.timeZone                     = [NSTimeZone defaultTimeZone];
        localN.soundName                    = sound.url.lastPathComponent;
        localN.userInfo                     = infoDict;
        localN.applicationIconBadgeNumber   = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
        
        [[UIApplication sharedApplication] scheduleLocalNotification:localN];
        
    //if app is active use the status bar overlay
    } else {
        CWStatusBarNotification *notification = [CWStatusBarNotification new];
        if ([pokemon isFav]) {
            notification.notificationLabelBackgroundColor = [UIColor colorWithRed:0.91 green:0.30 blue:0.24 alpha:1.0];
            notification.notificationLabelTextColor = [UIColor whiteColor];
        }
        [sound play];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        BOOL vibration = YES; // Default value
        
        if([prefs valueForKey:@"vibration"] != nil)
            vibration = [prefs boolForKey:@"vibration"];
        
        if(vibration) {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        }
        
        [notification displayNotificationWithMessage:message forDuration:4.5f];
        notification.notificationTappedBlock = ^(void) {
            [self.mapViewController.mapview setRegion:region animated:YES];
            //[self.mapViewController.mapview setCenterCoordinate:pokemon.location animated:YES];
        };
    }
}

- (void)serverChanged
{
    self.incomingIsFromNewConnection = YES;
}

#pragma mark - FRC Delegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            if ([anObject isKindOfClass:[Pokemon class]]) {
                Pokemon *pokemon = (Pokemon *)anObject;
                
                NSUserDefaults *prefs   = [NSUserDefaults standardUserDefaults];
                BOOL fav_notification   = YES; // Default value
                BOOL norm_notification  = YES; // Default value
                
                if([prefs valueForKey:@"fav_notification"] != nil)
                    fav_notification = [prefs boolForKey:@"fav_notification"]; // Object not set
                
                if([prefs valueForKey:@"norm_notification"] != nil)
                    norm_notification = [prefs boolForKey:@"norm_notification"]; // Object not set
                
                if (fav_notification && [pokemon isFav]) {
                    [self displayNotificationForPokemon:pokemon];
                }
                if (norm_notification && !self.incomingIsFromNewConnection) {
                    [self displayNotificationForPokemon:pokemon];
                }
                
            }
            break;
        }
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    self.incomingIsFromNewConnection = NO;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    
}

@end
