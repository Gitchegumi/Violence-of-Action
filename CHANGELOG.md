# Changelog

## [0.3.0](https://github.com/Gitchegumi/Violence-of-Action/compare/v0.2.0...v0.3.0) (2026-08-18)


### Features

* **input:** add controller setup entry ([2cac1d7](https://github.com/Gitchegumi/Violence-of-Action/commit/2cac1d7a35b051fb05fabfef60f8d60617266753)), closes [#100](https://github.com/Gitchegumi/Violence-of-Action/issues/100)


### Bug Fixes

* **input:** advance phases with controller start ([97dd1ec](https://github.com/Gitchegumi/Violence-of-Action/commit/97dd1ecb70709fccda646eb6441d09f417faaf3f)), closes [#100](https://github.com/Gitchegumi/Violence-of-Action/issues/100)
* **input:** complete controller camera navigation ([e3b903b](https://github.com/Gitchegumi/Violence-of-Action/commit/e3b903b1726d86adfa19fd63107dabf03d338803))
* **input:** complete controller navigation and camera pan ([d6d376d](https://github.com/Gitchegumi/Violence-of-Action/commit/d6d376dd873fcdddb4c30c1b8f587d04d8e89a9f))
* **input:** restore controller actions and camera pan ([80ebcdf](https://github.com/Gitchegumi/Violence-of-Action/commit/80ebcdf0923aac3b3728b1c14aa451d5a068e6c8))
* **ui:** advance focus after keyboard Done ([13af871](https://github.com/Gitchegumi/Violence-of-Action/commit/13af87138760604b912b3df4c000baed35fc30c1))
* **ui:** arm keyboard after opening release ([af9b8f6](https://github.com/Gitchegumi/Violence-of-Action/commit/af9b8f6496b1267ac8a24497e6455f3e2bbf11ac))
* **ui:** avoid hidden keyboard focus contention ([a04cb7b](https://github.com/Gitchegumi/Violence-of-Action/commit/a04cb7b9176410a7cd24b04eeecc2c9344b1a2c6)), closes [#100](https://github.com/Gitchegumi/Violence-of-Action/issues/100)
* **ui:** expose setup actions to controller ([e5e86dc](https://github.com/Gitchegumi/Violence-of-Action/commit/e5e86dc182e02bb2a751e7960d724d96a9002f1e))
* **ui:** guard controller popup opening inputs ([af8b92b](https://github.com/Gitchegumi/Violence-of-Action/commit/af8b92be0aaee759020438b9743ce28c38318c4e))
* **ui:** make keyboard Done controller-reachable ([ff1d98f](https://github.com/Gitchegumi/Violence-of-Action/commit/ff1d98fde7619c87016b834d47532de5fc7713b6))
* **ui:** make keyboard Done controller-reachable ([7380c4e](https://github.com/Gitchegumi/Violence-of-Action/commit/7380c4e994752713d2d3b40d96902ea4be439bae))
* **ui:** prevent color picker reopening on confirm ([162968a](https://github.com/Gitchegumi/Violence-of-Action/commit/162968ae6a1187777173cee5740a0a29dc510037))
* **ui:** prevent device zero double navigation ([b254318](https://github.com/Gitchegumi/Violence-of-Action/commit/b25431876ad08214051d6429901c0fb464a47b57))

## [0.2.0](https://github.com/Gitchegumi/Violence-of-Action/compare/v0.1.0...v0.2.0) (2026-08-16)


### Features

* **ui:** show complete combat equation ([5135757](https://github.com/Gitchegumi/Violence-of-Action/commit/5135757a9663561097eb583b3f207f9eefa6835e))
* **ui:** show complete combat equation ([cec444f](https://github.com/Gitchegumi/Violence-of-Action/commit/cec444f89bde69dc21a4c53caabbb3b851674676))

## 0.1.0 (2026-08-16)


### Features

* **input:** add controller hex cursor ([a4c67a4](https://github.com/Gitchegumi/Violence-of-Action/commit/a4c67a4682291e71baa800df80e063cc5cb9c37b))
* **input:** add gamepad radial navigation ([e644c27](https://github.com/Gitchegumi/Violence-of-Action/commit/e644c2772e787ddb4a9c8ecd61271d8faa55fc36))
* **release:** automate desktop release pipeline ([a78c591](https://github.com/Gitchegumi/Violence-of-Action/commit/a78c5916a679d2232974d9d8aec0b6cdebe17aa4))
* show selected unit movement remaining ([48e6f16](https://github.com/Gitchegumi/Violence-of-Action/commit/48e6f163ab7470158e0d8a4dab0653e49d74232e))
* **ui:** show remaining unit movement ([d054349](https://github.com/Gitchegumi/Violence-of-Action/commit/d054349e9ded5a0b78e7295efe4e7f825bb25182))


### Bug Fixes

* **ci:** tighten Godot export validation ([4bd9d9a](https://github.com/Gitchegumi/Violence-of-Action/commit/4bd9d9a2d6c204e2a2283159038062d7bd5c7682))
* **ci:** validate cold Godot exports ([041c6d2](https://github.com/Gitchegumi/Violence-of-Action/commit/041c6d21bb2c078f566362fe1e33e044c114c361))
* **input:** reset cursor state around radial menus ([70b7c64](https://github.com/Gitchegumi/Violence-of-Action/commit/70b7c64c88bc795b5c8bc6f2ab2434af7558eb1d))
* **input:** stabilize multi-gamepad cursor input ([a5aeac6](https://github.com/Gitchegumi/Violence-of-Action/commit/a5aeac6d9ae27bd8a2ae9483b49be3751ad298a7))
* **release:** complete smoke and recovery paths ([3fa59cf](https://github.com/Gitchegumi/Violence-of-Action/commit/3fa59cfc8117344be8337eae1d5fb1486f0f9c55))
* **tooling:** defer GUT plugin teardown ([e395002](https://github.com/Gitchegumi/Violence-of-Action/commit/e395002a3df90bc4410dee5ad2d1ae639c3bfffb))
* update main.tscn layout. ([8e4a580](https://github.com/Gitchegumi/Violence-of-Action/commit/8e4a580f14253f40236c7cce7a352f93b8751cc6))

## Changelog

All notable changes to Violence of Action are documented here. Releases use
[Semantic Versioning](https://semver.org/) while the game is in the `0.x` MVP stage.

## Unreleased

- Add local hot-seat setup for two to four named, color-coded players.
- Add edge deployment for all seven Coreborn unit types.
- Add hex-based movement, engagement, terrain, combat, and objective control.
- Add Essence income, Scavenger recruitment, and Coreborn special abilities.
- Add action cancellation, valid movement highlighting, and valid target highlighting.
