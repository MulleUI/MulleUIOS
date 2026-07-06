//
// main-image-desaturate.m
//
// Demonstrates CGContext imageByRenderingImage:withShader:uniforms:count:
//
// Displays source image on left, effect-processed copy on right.
// Cycles through different saturation/brightness combinations every 5 seconds.
//
#import "import-private.h"


#pragma mark - Test Bitmap

#define R   0xFF,0x00,0x00,0xFF
#define G   0x00,0xFF,0x00,0xFF
#define B   0x00,0x00,0xFF,0xFF
#define Y   0xFF,0xFF,0x00,0xFF
#define C   0x00,0xFF,0xFF,0xFF
#define M   0xFF,0x00,0xFF,0xFF
#define W   0xFF,0xFF,0xFF,0xFF
#define K   0x00,0x00,0x00,0xFF
#define O   0xFF,0x80,0x00,0xFF
#define P   0x80,0x00,0xFF,0xFF
#define T   0x00,0x80,0x80,0xFF
#define S   0xFF,0x80,0x80,0xFF
#define X   0x80,0x80,0x80,0xFF

static unsigned char   s_bitmap[ 4 * 8 * 8] =
{
   R, R, G, G,  B, B, Y, Y,
   R, R, G, G,  B, B, Y, Y,
   C, C, M, M,  W, W, X, X,
   C, C, M, M,  W, W, X, X,
   O, O, P, P,  T, T, S, S,
   O, O, P, P,  T, T, S, S,
   R, G, B, Y,  C, M, W, K,
   R, G, B, Y,  C, M, W, K
};


#pragma mark - Desaturation Shader

static char   s_vertexSource[] =
   "attribute vec3 vert;\n"
   "varying vec2 fragTexCoord;\n"
   "void main() {\n"
   //
   // Flip V: nvgluCreateFramebuffer forces NVG_IMAGE_FLIPY on the output
   // texture.  Nanovg will invert V when drawing it later, so we must
   // write pixels upside-down into the FBO to end up right-side-up.
   //
   "   fragTexCoord = vec2( (vert.x * 0.5) + 0.5, 0.5 - (vert.y * 0.5));\n"
   "   gl_Position  = vec4( vert, 1);\n"
   "}\n";

static char   s_fragmentSource[] =
   "precision mediump float;\n"
   "uniform sampler2D u_tex0;\n"
   "uniform float     u_saturation;\n"
   "uniform float     u_brightness;\n"
   "varying vec2      fragTexCoord;\n"
   "void main() {\n"
   "   vec4  color = texture2D( u_tex0, fragTexCoord);\n"
   "   float gray  = dot( color.rgb, vec3( 0.299, 0.587, 0.114));\n"
   "   color.rgb   = mix( vec3( gray), color.rgb, u_saturation) + u_brightness;\n"
   "   gl_FragColor = color;\n"
   "}\n";

static struct CGShaderUTF8Sources   s_shaderSources =
{
   "desaturate",
   s_vertexSource,
   s_fragmentSource,
   NULL,
   NULL
};


#pragma mark - Effect Presets

struct EffectPreset
{
   float        saturation;
   float        brightness;
   char         *name;
};

static struct EffectPreset   s_presets[] =
{
   { 0.0f,  0.0f,  "Grayscale" },
   { 1.0f,  0.3f,  "Brighten +0.3" },
   { 1.0f, -0.3f,  "Dim -0.3" },
   { 1.5f,  0.0f,  "Saturate 1.5x" },
   { 0.5f,  0.0f,  "Desaturate 50%" },
   { 0.5f,  0.2f,  "Desat 50% + Bright +0.2" },
   { 2.0f, -0.1f,  "Saturate 2x + Dim -0.1" }
};

#define PRESET_COUNT   (sizeof( s_presets) / sizeof( s_presets[0]))
#define SWITCH_SECONDS 5.0


#pragma mark - EffectLayer

@interface EffectLayer : CGGraphicsLayer
{
   CGImage        *_sourceImage;
   CGImage        *_processedImage;
   CGShaderID     _shader;
   CGFloat        _saturation;
   CGFloat        _brightness;
}

- (void) setSaturation:(CGFloat) saturation
            brightness:(CGFloat) brightness;

@end


@implementation EffectLayer

- (void) dealloc
{
   [_processedImage release];
   [_sourceImage release];

   [super dealloc];
}


- (void) setSaturation:(CGFloat) saturation
            brightness:(CGFloat) brightness
{
   if( _saturation == saturation && _brightness == brightness)
      return;

   _saturation = saturation;
   _brightness = brightness;

   [_processedImage release];
   _processedImage = nil;
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGRect              canvas;
   CGRect              leftRect;
   CGRect              rightRect;
   CGDrawableOptions   options;

   [super drawInContext:context];

   canvas = [self canvas];

   if( ! _sourceImage)
   {
      _sourceImage = [[CGImage alloc] initWithRGBABytes:s_bitmap
                                            bitmapSize:CGPixelSizeMake( 8, 8)
                                          textureFlags:CGImageFlagNearest
                                               context:context];
   }

   if( ! _shader)
      _shader = [context compileShaderWithShaderSources:&s_shaderSources];

   if( ! _processedImage)
   {
      struct CGUniform   uniforms[] =
      {
         { "u_saturation", CGUniformTypeFloat, { .floatValue = (float) _saturation } },
         { "u_brightness", CGUniformTypeFloat, { .floatValue = (float) _brightness } }
      };

      _processedImage = [[context imageByRenderingImage:_sourceImage
                                            withShader:_shader
                                              uniforms:uniforms
                                                 count:2] retain];
   }

   leftRect  = CGRectMake( canvas.origin.x, canvas.origin.y,
                           canvas.size.width / 2.0, canvas.size.height);
   rightRect = CGRectMake( canvas.origin.x + canvas.size.width / 2.0, canvas.origin.y,
                           canvas.size.width / 2.0, canvas.size.height);
   options   = CGDrawableOptionsMakeScaleToFit();

   [_sourceImage drawRect:leftRect
                  options:&options
                  context:context];
   if( _processedImage)
   {
      [_processedImage drawRect:rightRect
                        options:&options
                        context:context];
   }
   return( YES);
}

@end


#pragma mark - EffectView

@interface EffectView : UIView
{
   NSUInteger             _currentPreset;
   mulle_absolutetime_t   _startTime;
}
@end


@implementation EffectView

+ (Class) layerClass
{
   return( [EffectLayer class]);
}


- (void)    addLayer:(id <UILayer>) layer
       toRenderQueue:(struct mulle_pointerarray *) renderQueue
             context:(struct UIRenderQueueContext *) ctx
{
   EffectLayer          *effectLayer;
   UIWindow             *window;
   mulle_absolutetime_t  now;
   NSUInteger            newPreset;

   if( layer == (id <UILayer>) _mainLayer)
   {
      if( ! _startTime)
         _startTime = mulle_absolutetime_now();

      now       = mulle_absolutetime_now();
      newPreset = (NSUInteger) ((now - _startTime) / SWITCH_SECONDS);
      newPreset = newPreset % PRESET_COUNT;

      effectLayer = MULLE_OBJC_CLASS_CAST( EffectLayer, layer);

      if( newPreset != _currentPreset || ! _startTime)
      {
         struct EffectPreset   *preset;

         _currentPreset = newPreset;
         preset         = &s_presets[ _currentPreset];

         mulle_fprintf( stderr, "Effect: %s (sat=%.2f bri=%.2f)\n",
                  preset->name, preset->saturation, preset->brightness);

         window = MULLE_OBJC_CLASS_CAST( UIWindow, [self window]);
         [window setTitleUTF8String:preset->name];
      }

      [effectLayer setSaturation:s_presets[ _currentPreset].saturation
                      brightness:s_presets[ _currentPreset].brightness];
   }

   [super addLayer:layer
     toRenderQueue:renderQueue
           context:ctx];
}

@end


#pragma mark - Main

int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   EffectView      *view;

   app = [UIApplication sharedInstance];
   @autoreleasepool
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 200.0)
                         titleUTF8String:"Image Desaturate"
                               styleMask:UIWindowStyleMaskDefault];

      [window setBackgroundColor:CGColorMakeWithRGBA( 0.3, 0.3, 0.3, 1.0)];
      [window setFrameRateHz:1.0];

      view = [EffectView viewWithFrame:CGRectMake( 0.0, 0.0, 400.0, 200.0)];
      [[window contentView] addSubview:view];

      [app addWindow:window];
   }
   return( [app runApp]);
}
