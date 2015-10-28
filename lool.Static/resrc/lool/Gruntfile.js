module.exports = function(grunt) {
	grunt.initConfig({
		typescript: {
            options: {
                target: 'es5',
                removeComments: true,
                createMap: false
            },
    		amd: {
                options: {
                    module: 'amd',
                    basePath: 'ts/modules/'
                },
                src: 'ts/modules/**/*.ts',
                dest: 'js/modules/'
    		},
    		commonjs: {
                options: {
                    basePath: 'ts/'
                },
                src: ['ts/**/*.ts', '!ts/modules/**/*.ts'],
                dest: 'js/'
    		}
    	},
        uglify: {
            amd: {
                files: [{
                    expand: true,
                    cwd: 'js/modules/',
                    src: ['**/*.js', '!**/*.min.js'],
                    dest: 'js/modules/',
                    ext: '.min.js'
                }]
            }
        },
        less: {
            options: {
                compress: true
            },
            all: {
                src: 'less/all.less',
                dest: 'css/all.min.css',
            }
        },
        copy: {
            resrc: {
                options: {
                    filter: ['css', 'img', 'js', 'fonts'],
                    exclude: ['Gruntfile.js']
                },
                src: '../',
                dest: '../../../Website/resrc/'
            }
        }
	});
	
	grunt.loadNpmTasks('grunt-typescript');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-copy-files');

    grunt.file.setBase(__dirname);
    
    grunt.registerTask('default', ['typescript', 'uglify', 'less', 'copy']);
}