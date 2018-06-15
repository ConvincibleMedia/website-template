'use strict';
module.exports = function(grunt) {

	grunt.loadNpmTasks('grunt-shell');
	grunt.loadNpmTasks('grunt-concurrent');
	grunt.loadNpmTasks('grunt-postcss');
	grunt.loadNpmTasks('grunt-contrib-htmlmin');
	grunt.loadNpmTasks('grunt-contrib-uglify');

	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),

		dirs: {
			src: 'source',
			dest: 'public',
		},

		// =============
		// COMMANDS
		// =============

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
				command: 'node ./utils/backup/dato.backup.js'
			}
		},

		concurrent: { // Processing order within a concurrent set is not preserved (obviously)
			optimise: [
				'postcss:minify', 'htmlmin', 'uglify' // Output files are optimised
			]
		},


		// ===============
		// POST-PROCESSING
		// ===============

		postcss: {
			options: {
				map: false
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
			options: {
				removeComments: true,
				collapseWhitespace: true
			},
			public: { // Target
				files: [{
					expand: true,
					cwd: 'public/',
					src: ['**/*.html'],
					dest: 'public/'
				}]
			}
		},

		uglify: {
			options: {
				compress: true,
				mangle: false,
				sourceMap: false
			},
			public: {
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
		// Jekyll builds markdown/liquid
		'shell:jekyllBuild',
		// Post processing of compiled files now in /public/assets
		'postcss:autoprefix'
	]);
	grunt.registerTask('optimise', [
		// Minifies compiled files in /public/assets
		'concurrent:optimise'
	]);
	grunt.registerTask('serve', [
		'shell:jekyllServe'
	]);
	grunt.registerTask('backup', [
		'shell:datoBackup'
	]);

	grunt.registerTask('default', ['build', 'serve']);

};
