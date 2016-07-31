//
//  PokemonAnnotation.m
//  iPokeGo
//
//  Created by Dimitri Dessus on 22/07/2016.
//  Copyright © 2016 Dimitri Dessus. All rights reserved.
//

#import "PokemonAnnotation.h"

@implementation PokemonAnnotation

- (instancetype)initWithPokemon:(Pokemon *)pokemon andLocalization:(NSDictionary *)localization
{
    if (self = [super init]) {
        self.spawnpointID   = pokemon.spawnpoint;
        self.expirationDate = pokemon.disappears;
        self.coordinate     = pokemon.location;
        self.title          = [localization objectForKey:[NSString stringWithFormat:@"%@", @(pokemon.identifier)]];
        self.subtitle       = [NSString localizedStringWithFormat:NSLocalizedString(@"Disappears at", @"The hint in a annotation callout that indicates when a Pokémon disappears."),
                                [NSDateFormatter localizedStringFromDate:pokemon.disappears dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]];
        self.pokemonID      = pokemon.identifier;
    }
    return self;
}

@end
