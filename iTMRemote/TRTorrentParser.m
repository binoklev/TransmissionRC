//
//  TRTorrentParser.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 28.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRTorrentParser.h"

/*
 *
 Числа задаются в форме i<последовательность цифр>e, <последовательность цифр> — это цифры в ascii представлении, то есть 1 задаётся как '1' или 0x31. Заметно что так мы можем задавать огромные числа, которые не влезут ни в long, ни в long long, однако большинство пренебрегают отсутствием лимита и используют 64-битные числа.
 Массив байт — <длина массива>:<сам массив>. Длина массива так же формируется неограниченной последовательностью цифр.
 Список — l<элемeнты списка>e. Элементом может являться любой из типов данных. В том числе и вложенный список. Конец, как видно из формата, отмечается литералом 'e'.
 Ассоциативный массив — d<элемeнты массива>e. Каждый элемент массива выглядит таким образом — <массив байт><элемент>. Массив байт — это имя записи в форме из пункта 2. Элемент опять же может быть любым — список, массив, ассоциативный массив, число.
 
 */

@interface TRTorrentParser() {
    uint8_t *_maxPointer;
}

@end

@implementation TRTorrentParser

- (NSDictionary*)parseBuffer:(NSData*)data {
    // check format
    if (*(uint8_t*)[data bytes] != 'd') {
        return nil;
    }
    // pointer to buffer end
    _maxPointer = (uint8_t*)[data bytes] + [data length];
    
    NSDictionary *dic;
    uint8_t *finish = [self parseBuffer:(uint8_t*)[data bytes] toDictionary:&dic];
    // check parsing result
    if (finish == NULL || dic == nil) {
        return nil;
    }
    DLog(@"Dictionary parsed");
    return dic;
}

- (uint8_t*)parseBuffer:(uint8_t*)pBuffer toDictionary:(NSDictionary**)dictionary {
    NSAssert(*pBuffer == 'd', @"Buffer is not a dictionary!!!");
    uint8_t *p = pBuffer + 1;
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    while (*p != 'e' && p < _maxPointer) {
        NSString *key;
        p = [self parseBuffer:p toString:&key];
        if (p==NULL || key==nil) {
            *dictionary = nil;
            return NULL;
        }
        
        id value;
        if ([@"pieces" isEqualToString:key]) {
            p = [self parseBuffer:p toData:&value];
            if (p==NULL || key==nil) {
                *dictionary = nil;
                return NULL;
            }
        }
        else {
            p = [self parseBuffer:p toObject:&value];
            if (p==NULL || key==nil) {
                *dictionary = nil;
                return NULL;
            }
        }
        
        [dic setObject:value forKey:key];
        
    }
    *dictionary = dic;
    return ++p;
}

#define IS_NUM(p) (*p >= '0' && *p <= '9')
- (uint8_t*)parseBuffer:(uint8_t*)pBuffer toObject:(id*)obj {
    uint8_t *p = pBuffer;
    id result = nil;
    
    if (*p == 'd') {
        p = [self parseBuffer:p toDictionary:&result];
    }
    else if (*p == 'l') {
        p = [self parseBuffer:p toArray:&result];
    }
    else if (*p == 'i') {
        p = [self parseBuffer:p toNumber:&result];
    }
    else if ( IS_NUM(pBuffer) ) {
        p = [self parseBuffer:p toString:&result];
    }
    if (p==NULL || result==nil) {
        *obj = nil;
        return NULL;
    }
    
    *obj = result;
    return p;
}

- (uint8_t*)parseBuffer:(uint8_t*)pBuffer toArray:(NSArray**)array {
    NSAssert(*pBuffer == 'l', @"Buffer is not a list!!!");
    uint8_t *p = pBuffer + 1;
    NSMutableArray *marr = [NSMutableArray array];
    while (*p != 'e' && p < _maxPointer) {
        
        id result;
        p = [self parseBuffer:p toObject:&result];
        if (p==NULL || result==nil) {
            DLog(@"Parsed array is null!!!");
            *array = nil;
            return NULL;
        }
        else {
            [marr addObject:result];
        }
        *array = marr;
    }
    return ++p;
}

#define NOT_NUM(p) (*p < 0x30 || *p > 0x39)

- (uint8_t*)parseBuffer:(uint8_t*)pBuffer toString:(NSString**)string {
    
    if ( NOT_NUM(pBuffer) ) {
        DLog(@"Buffer is not a number string: %c", *pBuffer);
        *string = nil;
        return NULL;
    }
    uint8_t *p = pBuffer;
    while (*(++p) != ':') {
        if (NOT_NUM(p)) {
            DLog(@"Wrong numeric string, contain: %c", *p);
            *string = nil;
            return NULL;
        }
        if (p >= _maxPointer) {
            DLog(@"Unexpected end of the buffer.!!!");
            *string = nil;
            return NULL;
        }
    }
    
    NSString *str = [[NSString alloc] initWithBytes:pBuffer length:(p-pBuffer) encoding:NSUTF8StringEncoding];
    if (str == nil) {
        DLog(@"Numeric string is null!!!");
        *string = nil;
        return NULL;
    }
    unsigned long len = (unsigned long)[str longLongValue];
    if (++p + len > _maxPointer) {
        DLog(@"Unexpected end of the buffer.!!!");
        *string = nil;
        return NULL;
    }
    str = [[NSString alloc] initWithBytes:p length:(NSUInteger)len encoding:NSUTF8StringEncoding];
    if (str == nil) {
        // copy string to new buffer
        void *vp = malloc(len);
        memcpy(vp, p, len);
        uint8_t *cp = vp;
        // check symbols correctness and replce incorrect with '_'
        while ((void*)cp < vp+len) {
            if (*cp < 0x80) {
                // (1 байт)  0aaa aaaa
                cp++;
            }
            else {
                // (2 байта) 110x xxxx 10xx xxxx
                if ( (*cp & 0xE0) == 0xC0 ) {
                    // check second symbol
                    if ( *(cp+1) && 0xC0 == 0x80)
                        // correct symbol format
                        cp+=2;
                    else {
                        // replace with '_'
                        *cp = '_';
                        cp++;
                    }
                }
                // (3 байта) 1110 xxxx 10xx xxxx 10xx xxxx
                else if ((*cp & 0xF0) == 0xE0) {
                    if ( (*(cp+1) && 0xC0 == 0x80) && (*(cp+2) && 0xC0 == 0x80) )
                        // correct symbol format
                        cp+=3;
                    else {
                        // replace with '_'
                        *cp = '_';
                        cp++;
                    }
                }
                // (4 байта) 1111 0xxx 10xx xxxx 10xx xxxx 10xx xxxx
                else if ((*cp & 0xF8) == 0xF0) {
                    if ( (*(cp+1) && 0xC0 == 0x80) && (*(cp+2) && 0xC0 == 0x80) && (*(cp+3) && 0xC0 == 0x80) )
                        // correct symbol format
                        cp+=4;
                    else {
                        // replace with '_'
                        *cp = '_';
                        cp++;
                    }
                }
                // (5 байт)  1111 10xx 10xx xxxx 10xx xxxx 10xx xxxx 10xx xxxx
                else if ((*cp & 0xFC) == 0xF8) {
                    if ( (*(cp+1) && 0xC0 == 0x80) && (*(cp+2) && 0xC0 == 0x80) && (*(cp+3) && 0xC0 == 0x80) && (*(cp+4) && 0xC0 == 0x80) )
                        // correct symbol format
                        cp+=5;
                    else {
                        // replace with '_'
                        *cp = '_';
                        cp++;
                    }
                }
                // (6 байт)  1111 110x 10xx xxxx 10xx xxxx 10xx xxxx 10xx xxxx 10xx xxxx
                else if ((*cp & 0xFE) == 0xFC) {
                    if ( (*(cp+1) && 0xC0 == 0x80) && (*(cp+2) && 0xC0 == 0x80) && (*(cp+3) && 0xC0 == 0x80) && (*(cp+4) && 0xC0 == 0x80) && (*(cp+6) && 0xC0 == 0x80) )
                        // correct symbol format
                        cp+=6;
                    else {
                        // replace with '_'
                        *cp = '_';
                        cp++;
                    }
                }
            }
        }
        // try to make string again
        str = [[NSString alloc] initWithBytes:vp length:len encoding:NSUTF8StringEncoding];
        free(vp);
        if (str == nil) {
            DLog(@"Parsed string is null!!!");
            *string = nil;
            return NULL;
        }
    }
    *string = str;
    // add length
    return p + len;
}

- (uint8_t*)parseBuffer:(uint8_t*)pBuffer toNumber:(NSNumber**)number {
    NSAssert(*pBuffer == 'i', @"Buffer is not a i-number string!!!");

    uint8_t *p = pBuffer+1;
    while (*p != 'e') {
        p++;
        if (p >= _maxPointer) {
            DLog(@"Unexpected end of the buffer.!!!");
            *number = nil;
            return NULL;
        }
    }
    NSString *str = [[NSString alloc] initWithBytes:(pBuffer+1) length:(p-pBuffer-1) encoding:NSUTF8StringEncoding];
    if (str == nil) {
        DLog(@"Numeric string is null!!!");
        *number = nil;
        return NULL;
    }
    *number = [NSNumber numberWithLongLong:[str longLongValue]];
    // shift to next symbol after
    p++;
    return p;
}

- (uint8_t*)parseBuffer:(uint8_t*)pBuffer toData:(NSData**)data {
    NSAssert( *pBuffer >= 0x30 && *pBuffer <= 0x39, @"Buffer is not a bytes: %c", *pBuffer);
    uint8_t *p = pBuffer;
    while (*(++p) != ':') {
        if (NOT_NUM(p)) {
            DLog(@"Wrong numeric string, contain: %c", *p);
            *data = nil;
            return NULL;
        }
        if (p >= _maxPointer) {
            DLog(@"Unexpected end of the buffer.!!!");
            *data = nil;
            return NULL;
        }
    }
    NSString *str = [[NSString alloc] initWithBytes:pBuffer length:(p-pBuffer) encoding:NSUTF8StringEncoding];
    if (str == nil) {
        DLog(@"Numeric string is null!!!");
        *data = nil;
        return NULL;
    }
    long long len = [str longLongValue];
    *data = [NSData dataWithBytes:++p length:(NSUInteger)len];
    // add length
    return p + len;
}

@end
