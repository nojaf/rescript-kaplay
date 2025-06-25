# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/)
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]
### Added
- More easing functions to `Types.easingMap`
- `Fixed` component
- `Layer` component
- `setLayers` to `Context`

## [0.8.0] - 2025-06-23
### Added
- Add `onDraw` and `drawXYZ` to `Context`
- `Rect`, `Circle` and `Polygon` to `Math`
- More `keys` in `Types`
- `screenPos` to `Pos`
- `circle`, `rect`, `polygon` (math shapes) to `Types`
- `color` type instance bindings to `Color`
- Color constants to `Color`
- `loadSprite` to `Context`

### Removed
- `Context.mathRect`, use `Math.Rect.make` instead
- `Context.mathCircle`, use `Math.Circle.make` instead
- `Context.mathPolygon`, use `Math.Polygon.make` instead
- `Context.colorFromHex`, use `Color.fromHex` instead

## [0.7.0] - 2025-06-16
### Added
- `addAnchorFromVec2` to `Anchor`
- `colorFromRGB` to `Context`
- `getSprite` to `Context`
- `spriteAtlasPadding` to `kaplayOptions`
- `loadFont` to `Context`

### Changed
- `width` to float for `Outline`

## [0.6.0] - 2025-06-10
### Added
- `deg2rad` and `rad2deg` to `Context`
- `tweenWithController` to `Context`
- `toWorld` and `toScreen` to `Context`
- `getChildren` and `removeAll` to `GameObjRaw`
- `Timer` component
- `animation` to `Animate`

### Removed
- `Types.component`, use `CustomComponent.t`

## [0.5.0] - 2025-06-06
### Added
- `Animate` component
- `Polygon` component
- `CustomComponent` module for [https://v4000.kaplayjs.com/guides/custom_components/](custom components)
- `drawLines` in `Context`
- `addColorFromHex` and `addColorFromRgb` in `Color` component
- `Shader` component
- `UVQuad` component
- `loadShader` and `time` to `Context`

### Changed
- Moved `easeFunc` & `easeMap` to `Types`

## [0.4.0] - 2025-06-05
### Added
- `Ellipse` component

### Changed
- Rename `GameObjRaw.add` to `addChild`

## [0.3.0] - 2025-06-04
### Added
- `mousePos`, `onMousePress`, `onMouseMove` & `onMouseRelease` in `Context`
- `PatrolComp`

## [0.2.0] - 2025-06-03
### Added
- `use` binding for `GameObjRaw`
- getters and setters for `width` and `height` in `Rect`
- `crisp` to `Context.kaplayOptions`
- `paused` and `stop` to `AudioPlay`

### Changed
- correct `onHover` bindings for `Area`

### Fixed
- correct `clampFloat` import

## [0.1.0] - 2025-05-31
Initial version
