allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build directory to the root to keep the project clean
rootProject.layout.buildDirectory.set(rootProject.layout.projectDirectory.dir("../build"))

subprojects {
    val newSubprojectBuildDir: Directory = rootProject.layout.buildDirectory.dir(project.name).get()
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    // Only apply dependency on :app for projects that aren't :app itself
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }

    // Force all Android subprojects (plugins) to use modern SDK and Build Tools
    // This resolves the "25.0.2" build-tools error caused by outdated plugins.
    project.plugins.withId("com.android.library") {
        val android = project.extensions.getByName("android")
        
        // Use reflection as a safe bridge to override properties in older plugins
        try {
            // Force Compile SDK and Build Tools
            val setCompileSdk = android.javaClass.methods.find { it.name == "setCompileSdk" && it.parameterCount == 1 }
            setCompileSdk?.invoke(android, 35)
            
            val setBuildToolsVersion = android.javaClass.methods.find { it.name == "setBuildToolsVersion" && it.parameterCount == 1 }
            setBuildToolsVersion?.invoke(android, "35.0.0")

            // Namespace fallback logic
            val getNamespace = android.javaClass.methods.find { it.name == "getNamespace" }
            val setNamespace = android.javaClass.methods.find { it.name == "setNamespace" && it.parameterCount == 1 }

            if (getNamespace != null && setNamespace != null) {
                val currentNamespace = getNamespace.invoke(android)
                if (currentNamespace == null) {
                    val fallbackNamespace = project.group.toString().takeIf { it.isNotBlank() && it != "unspecified" }
                            ?: "com.plugin.missing.namespace.${project.name.replace("-", ".")}"
                    setNamespace.invoke(android, fallbackNamespace)
                }
            }
        } catch (e: Exception) {
            // Ignore if reflection fails for specific modern plugins that don't need it
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
