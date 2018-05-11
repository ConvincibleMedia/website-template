'use strict';
module.exports = function(grunt) {

	grunt.loadNpmTasks('grunt-shell');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-concurrent');
	grunt.loadNpmTasks('grunt-sass');
	grunt.loadNpmTasks('grunt-postcss');
	grunt.loadNpmTasks('grunt-contrib-htmlmin');
	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.loadNpmTasks('grunt-includes');

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
				command: 'node dato.backup.js'
			}
		},

		concurrent: {
			optimise: [
				'postcss:minify', 'htmlmin', 'uglify' // Output files are optimised
			]
		},


		// =============
		// FILES
		// =============

		clean: ['public'], // NO LEADING SLASH

		copy: {
			vendors: {
				files: [{
					expand: true,
					cwd: 'source/assets/',
					src: [
						'js/vendor/head/**/*.*',
						'js/vendor/html5shiv/**/*.*',
						'js/vendor/jquery/**/*.*',
					],
					dest: 'public/assets/'
				}],
			},
		},


		// =============
		// CONCATENATION
		// =============

		includes: {
			js: {
				options: {
					includeRegexp: /^(\s*)\/\/\s*@import\s+['"]?([^'"]+)['"]?\s*$/, // = commented but equiv to SASS syntax
					duplicates: false,
					debug: true,
					filenameSuffix: '.js' // Don't have to specify in include
				},
				files: [{
					expand: true,
					cwd: 'source/assets/js/',
					src: [
						'features/*.js',
						'layouts/*.js',
						'*.js',
					],
					dest: 'public/assets/js/',
					ext: '.js'
				}]
			},
		},


		// =============
		// COMPILATION
		// =============

		sass: {
			options: {
				sourceMap: true,
				relativeAssets: false,
				outputStyle: 'expanded',
					// nested = show selector depth structure
					// expanded = prettified like a human would write it
					// compact = one line per selector/properties
					// compressed = minified
				sassDir: 'source/assets/css',
				cssDir: 'public/assets/css'
			},
			build: {
				files: [{
					expand: true,
					cwd: 'source/assets/css/',
					src: [
						'features/*.scss',
						'layouts/*.scss',
						'*.scss'
					],
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
		'clean',
		// Jekyll builds markdown/liquid
		'shell:jekyllBuild',
		// Concatenate files and
		// Compile higher-order languages
		'sass', 'includes:js',
		// Post processing of /public
		'postcss:autoprefix',
		// Other static files to move over
		'copy:vendors'
	]);
	grunt.registerTask('optimise', [
		// Operates on the public directory
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
