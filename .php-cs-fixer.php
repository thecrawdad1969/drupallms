<?php

$finder = PhpCsFixer\Finder::create()
    ->in([__DIR__ . '/'])
    ->name('*.php', '*.module');

$finder1 = PhpCsFixer\Finder::create()
    ->in(['vendor/drush/drush/src'])
    ->name('*.php', '*.module');

return (new PhpCsFixer\Config())
    ->setFinder($finder, $finder1)
    ->setRules([
        'nullable_type_declaration_for_default_null_value' => true,
    ]);