'use strict';
module.exports = function(grunt) {

   grunt.loadNpmTasks('grunt-shell');
   grunt.loadNpmTasks('grunt-concurrent');
   grunt.loadNpmTasks('grunt-sass');
   grunt.loadNpmTasks('grunt-postcss');
   grunt.loadNpmTasks('grunt-contrib-htmlmin');
   grunt.loadNpmTasks('grunt-contrib-uglify');

   grunt.initConfig({
      pkg: grunt.file.readJSON('package.json'),

      shell: {
         jekyllBuild: {
            command: 'jekyll build'
         },
         jekyllServe: {
            command: 'jekyll serve --no-watch --skip-initial-build'
         },
         datoDump: {
            command: 'bundle exec dato dump'
         },
         datoBackup: {
            command: 'node dato.backup.js'
         }
      },

      concurrent: {
         optimise: [
            'postcss:minify', 'htmlmin', 'uglify' // Output files are optimised
         ]
      },

      // =============
      // BUILD PROCESS
      // =============

      sass: {
         options: {
            sourceMap: true,
            relativeAssets: false,
            outputStyle: 'expanded',
            sassDir: 'source/assets/css',
            cssDir: 'public/assets/css'
         },
         build: {
            files: [{
               expand: true,
               cwd: 'source/assets/css/',
               src: ['**/*.scss'],
               dest: 'public/assets/css/',
               ext: '.css'
            }]
         }
      },

      // ===============
      // POST-PROCESSING
      // ===============

      postcss: {
         options: {
            map: true
         },
         autoprefix: {
            options: {
               processors: [
                  require('autoprefixer')({
                     remove: false,
                     grid: true
                  })
               ]
            },
            src: 'public/assets/css/**/*.css'
         },
         minify: {
            options: {
               processors: [
                  require('cssnano')()
               ]
            },
            src: 'public/assets/css/**/*.css'
         }
      },

      htmlmin: {
         prod: { // Target
            options: {
               removeComments: true,
               collapseWhitespace: true
            },
            files: [{
               expand: true,
               cwd: 'public/',
               src: ['**/*.html'],
               dest: 'public/'
            }]
         }
      },

      uglify: {
         prod: {
            options: {
               compress: true,
               mangle: false,
               sourceMap: true
            },
            files: [{
               expand: true,
               cwd: 'public/assets/js/',
               src: ['**/*.js', '!**/*.min.js'],
               dest: 'public/assets/js/'
            }]
         }
      }

   });

   grunt.registerTask('build', [
      'shell:jekyllBuild', // Jekyll builds markdown/liquid
      'sass', 'postcss:autoprefix'
   ]);
   grunt.registerTask('optimise', [
      'concurrent:optimise'
   ]);
   grunt.registerTask('serve', [
      'shell:jekyllServe'
   ]);
   grunt.registerTask('backup', [
      'shell:datoBackup'
   ]);

   grunt.registerTask('default', 'build');

};
