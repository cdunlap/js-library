# global config:true, file:true, task:true, module: true

timer = require 'grunt-timer'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
  timer.init(grunt)

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    clean: ['build']
    coffee:
      build:
        files: [
          { src: ['**/*.coffee'], cwd: 'app', dest: 'build', ext: '.js', expand: true }
        ]
    concat:
      jail_iframe:
        src: [
          'build/js/jail_iframe/config/*'
          'build/js/jail_iframe/libs/*'
          'build/js/jail_iframe/core.js'
          'build/js/jail_iframe/wrap/first.js'
          'build/js/jail_iframe/classes/*.js'
          'build/js/jail_iframe/util/*.js'
          'build/js/jail_iframe/initializers/*.js'
          'build/js/jail_iframe/wrap/last.js'
        ]
        dest: 'build/js/jail_iframe.js'
    sass:
      build:
        options:
          bundleExec: true
          noCache: true #workaround for https://github.com/gruntjs/grunt-contrib-sass/issues/63
        files:
          'build/css/basic_without_embeds.css': 'app/css/basic.scss'
          'build/css/framed_controls_without_embeds.css': 'app/css/framed_controls.scss'
    cssUrlEmbed:
      encodeDirectly:
        files:
          'build/css/basic.css': ['build/css/basic_without_embeds.css']
          'build/css/framed_controls.css': ['build/css/framed_controls_without_embeds.css']
    cssmin:
      build:
        expand: true
        cwd: 'build/css/'
        dest: 'build/css/'
        src: '*.css'
        ext: '.min.css'
    uglify:
      options:
        preserveComments: (node, comment) -> !comment.value.lastIndexOf('@license', 0)
      jail_iframe:
        files:
          'build/js/jail_iframe.min.js':                        ['build/js/jail_iframe.js']
      factlink_loader:
        files:
          'build/js/loader/loader_common.min.js':       ['build/js/loader/loader_common.js']
    shell:
      gzip_js_files:
        command: ' find build/js/loader/ -iname \'*.js\'  -maxdepth 1  -exec bash -c \' gzip -9 -f < "{}" > "{}.gz" \' \\; '

    copy:
      dist_loader_aliases:
        files: [
          { src: 'build/js/loader/loader_common.js', dest: 'output/dist/factlink_loader_basic.js' }
          { src: 'build/js/loader/loader_common.js', dest: 'output/dist/factlink_loader_publishers.js' }
          { src: 'build/js/loader/loader_common.js', dest: 'output/dist/factlink_loader_bookmarklet.js' }
          
          { src: 'build/js/loader/loader_common.min.js', dest: 'output/dist/factlink_loader_basic.min.js' }
          { src: 'build/js/loader/loader_common.min.js', dest: 'output/dist/factlink_loader_publishers.min.js' }
          { src: 'build/js/loader/loader_common.min.js', dest: 'output/dist/factlink_loader_bookmarklet.min.js' }
          
          { src: 'build/js/loader/loader_common.js.gz', dest: 'output/dist/factlink_loader_basic.js.gz' }
          { src: 'build/js/loader/loader_common.js.gz', dest: 'output/dist/factlink_loader_publishers.js.gz' }
          { src: 'build/js/loader/loader_common.js.gz', dest: 'output/dist/factlink_loader_bookmarklet.js.gz' }

          { src: 'build/js/loader/loader_common.min.js.gz', dest: 'output/dist/factlink_loader_basic.min.js.gz' }
          { src: 'build/js/loader/loader_common.min.js.gz', dest: 'output/dist/factlink_loader_publishers.min.js.gz' }
          { src: 'build/js/loader/loader_common.min.js.gz', dest: 'output/dist/factlink_loader_bookmarklet.min.js.gz' }
        ]

      config_development:
        files: [
          { src: ['development.js'], cwd: 'build/config', dest: 'build/js/jail_iframe/config', expand: true }
        ]
      config_staging:
        files: [
          { src: ['staging.js'], cwd: 'build/config', dest: 'build/js/jail_iframe/config', expand: true }
        ]
      config_production:
        files: [
          { src: ['production
.js'], cwd: 'build/config', dest: 'build/js/jail_iframe/config', expand: true }
        ]
      build:
        files: [
          { src: ['**/*.js', '**/*.png', '**/*.gif', '**/*.woff', 'robots.txt'], cwd: 'app', dest: 'build', expand: true }
        ]
      dist_static_content:
        files: [
          { src: ['robots.txt', 'images/**/*'], cwd: 'build', dest: 'output/dist', expand: true }
        ]
    watch:
      files: ['app/**/*', 'Gruntfile.coffee']
      tasks: ['default']
    mocha:
      test:
        src: ['tests/**/*.html']
        options:
          run: true

  grunt.task.registerTask 'code_inliner', 'Inline code from one file into another',  ->
    min_filename = (filename) -> filename.replace(/\.\w+$/,'.min$&')
    debug_filename = (filename) -> filename
    file_variant_funcs = [min_filename, debug_filename]
    replacements = [
      {
        placeholder: '__INLINE_CSS_PLACEHOLDER__'
        content_file: 'build/css/basic.css'
      }
      {
        placeholder: '__INLINE_FRAME_CSS_PLACEHOLDER__'
        content_file: 'build/css/framed_controls.css'
      }
      {
        placeholder: '__INLINE_JS_PLACEHOLDER__'
        content_file: 'build/js/jail_iframe.js'
      }
    ]
    file_variant_funcs.forEach (file_variant_func) ->
      replacements.forEach (replacement) ->
        input_filename = file_variant_func(replacement.content_file)
        input_content = grunt.file.read(input_filename, 'utf8')
        input_content_stringified = JSON.stringify(input_content)
        target_filename = file_variant_func 'build/js/loader/loader_common.js'

        grunt.log.writeln "Inlining '#{input_filename}' into '#{target_filename}' where  '#{replacement.placeholder}'."
        target_content = grunt.file.read target_filename, 'utf8'
        target_with_inlined_content = target_content.replace replacement.placeholder, input_content_stringified
        grunt.file.write(target_filename, target_with_inlined_content)

  grunt.registerTask 'preprocessor', [
    'clean', 'copy:build', 'coffee', 'sass', 'cssUrlEmbed', 'cssmin', ]

  grunt.registerTask 'postprocessor', [
    'concat', 'mocha', 'uglify', 'code_inliner', 'shell:gzip_js_files', 'copy:dist_loader_aliases', 'copy:dist_static_content' ]

  grunt.registerTask 'compile_development', [ 'preprocessor', 'copy:config_development', 'postprocessor' ]
  grunt.registerTask 'compile_staging',     [ 'preprocessor', 'copy:config_staging',     'postprocessor' ]
  grunt.registerTask 'compile_production',  [ 'preprocessor', 'copy:config_production',  'postprocessor' ]

  grunt.registerTask 'default', ['compile_development']

  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-css-url-embed'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-mocha'
