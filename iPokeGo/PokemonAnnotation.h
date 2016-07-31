//
//  PokemonAnnotation.h
//  iPokeGo
//
//  Created by Dimitri Dessus on 22/07/2016.
//  Copyright © 2016 Dimitri Dessus. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "CoreDataEntities.h"

@interface PokemonAnnotation : MKPointAnnotation

@property int pokemonID;
@property NSDate *expirationDate;
@property NSString *spawnpointID;

- (instancetype)initWithPokemon:(Pokemon *)pokemon andLocalization:(NSDictionary *)localization;

@end
