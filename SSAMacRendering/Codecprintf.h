//
//  Codecprintf.h
//  SSAMacRendering
//
//  Created by C.W. Betts on 8/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#ifndef Codecprintf_h
#define Codecprintf_h

#include <stdio.h>

#define Codecprintf(dest, ...) fprintf(dest ?: stderr, __VA_ARGS__ )


#endif /* Codecprintf_h */
