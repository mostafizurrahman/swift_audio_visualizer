//
//  Music_Player-Bridging-Header.h
//  Music Player
//
//  Created by Mostafizur Rahman on 7/2/19.
//  Copyright © 2019 polat. All rights reserved.
//

#ifndef Music_Player_Bridging_Header_h
#define Music_Player_Bridging_Header_h

#include "MeterTable.h"
#ifdef __cplusplus
extern "C" {
#endif
    
    float getMeterValue(float power);
    
#ifdef __cplusplus
}
#endif
#endif /* Music_Player_Bridging_Header_h */
