import Foundation
import SourceryRuntime

// MARK: - Public API

public extension Type {
    /**
     Declares additional 'non-model' `ViewBuilder` generic types
     Follows list of `componentProperties.templateParameterDecls`
     ```
     struct AcmeComponent<Title: View, /* starts here => */ AcmeView: View, ...
     ```
     */
    var add_view_builder_paramsTemplateParameterDecls: [String] {
        resolvedAnnotations("add_view_builder_params").map { "\($0.capitalizingFirst()): View" }
    }
}

extension Type {
    func viewBuilderProperties(in context: [String: Type]) -> [(name: String, type: String)] {
        let componentProperties = flattenedComponentProperties(contextType: context).map { (name: $0.name, type: $0.name.capitalizingFirst()) }
        let addViewBuilderProperties = resolvedAnnotations("add_view_builder_params").map { (name: $0, type: $0.capitalizingFirst()) }
        return [componentProperties, addViewBuilderProperties].flatMap { $0 }
    }
}

public extension Type {
    var componentName: String {
        name.replacingOccurrences(of: "Model", with: "")
    }

    var componentNameAsPropertyDecl: String {
        self.componentName.lowercasingFirst()
    }

    func flattenedComponentProperties(contextType: [String: Type]) -> [Variable] {
        inheritedTypes.compactMap { contextType[$0] }.flatMap { $0.allVariables }
    }

    func resolvedAnnotations(_ name: String) -> [String] {
        if let string = self.annotations[name] as? String {
            return [string]
        } else if let array = self.annotations[name] as? [String] {
            return array
        } else {
            return []
        }
    }
    
    var add_view_builder_paramsViewBuilderPropertyDecls: [String] {
        self.resolvedAnnotations("add_view_builder_params")
            .map { "private let _\($0): \($0.capitalizingFirst())" }
    }
    
    var add_view_builder_paramsViewBuilderInitParams: [String] {
        self.resolvedAnnotations("add_view_builder_params")
            .map { "@ViewBuilder \($0): @escaping () -> \($0.capitalizingFirst())" }
    }

    var add_view_builder_paramsViewBuilderInitParamAssignment: [String] {
        self.resolvedAnnotations("add_view_builder_params")
            .map { "self._\($0) = \($0)()" }
    }
    
    var add_view_builder_paramsResolvedViewModifierChain: [String] {
        self.resolvedAnnotations("add_view_builder_params")
            .map {
                """
                var \($0): some View {
                        _\($0)
                    }
                """
            }
    }
    
    var add_view_builder_paramsExtensionModelInitParamsChaining: [String] {
        self.resolvedAnnotations("add_view_builder_params")
            .map { "\($0): \($0)" }
    }
    
    var add_env_propsDecls: [String] {
        self.resolvedAnnotations("add_env_props")
            .map { "@Environment(\\.\($0)) var \($0)" }
    }

    func add_public_propsDecls(indent level: Int) -> String {
        self.resolvedAnnotations("add_public_props")
            .map { "public let \($0)" }.joined(separator: carriageRet(level))
    }

    // Not used when Style/Configuration is not adopted
    var componentStyleName: String {
        "\(self.componentName)tStyle"
    }

    // Not used when Style/Configuration is not adopted
    var componentStyleNameAsPropertyDecl: String {
        self.componentStyleName.lowercasingFirst()
    }

    // Not used when Style/Configuration is not adopted
    var stylePropertyDecl: String {
        "@Environment(\\.\(self.componentNameAsPropertyDecl)Style) var style: Any\(self.componentStyleName)"
    }

    // Not used when Style/Configuration is not adopted
    var componentStyleConfigurationName: String {
        "\(self.componentStyleName)Configuration"
    }

    // Not used when Style/Configuration is not adopted
    var fioriComponentStyleName: String {
        "Fiori\(self.componentStyleName)"
    }

    // Not used when Style/Configuration is not adopted
    var fioriLayoutRouterName: String {
        "Fiori\(self.componentName)LayoutRouter"
    }

//    public var usage: String {
//        "\(componentName) \(componentProperties.usage)"
//    }
//
//    public var acmeUsage: String {
//        "\(componentName) \(componentProperties.acmeUsage)"
//    }

    func fioriStyleImplEnumDecl(componentProperties: [Variable]) -> String {
        """
        extension Fiori {
            enum \(self.componentName) {
                \(componentProperties.typealiasViewModifierDecls)

                // TODO: - substitute type-specific ViewModifier for EmptyModifier
                /*
                    // replace `typealias Subtitle = EmptyModifier` with:

                    struct Subtitle: ViewModifier {
                        func body(content: Content) -> some View {
                            content
                                .font(.body)
                                .foregroundColor(.preferredColor(.primary3))
                        }
                    }
                */
                \(componentProperties.staticViewModifierPropertyDecls)
            }
        }
        """
    }

    internal var closureProperties: [Variable] {
        var closureProperties: [Variable] = []

        for method in self.methods {
            let v = Variable(name: "\(method.name)Closure", typeName: method.returnTypeName, type: Type(), accessLevel: (read: .internal, write: .internal), isComputed: true, isStatic: false, defaultValue: nil, attributes: [:], annotations: [:], definedInTypeName: method.definedInTypeName)
            closureProperties.append(v)
        }

        return closureProperties
    }

    internal func closureProperties(contextType: [String: Type]) -> [Variable] {
        inheritedTypes.compactMap { contextType[$0] }.flatMap { $0.allMethods }.map { (method) -> Variable in

            let name = "\(method.name.components(separatedBy: "(").first ?? method.selectorName)Closure"

            let parameterListAsString: String = method.parameters.map { "\($0.typeName)" }.joined(separator: ",")
            let typeName = TypeName("((\(parameterListAsString)) -> \(method.returnTypeName))?")

            var convertionAnnotations: [String: NSObject] = [:]
            convertionAnnotations["originalMethod"] = method

            return Variable(name: name, typeName: typeName, type: Type(), accessLevel: (read: SourceryRuntime.AccessLevel(rawValue: method.accessLevel)!, write: SourceryRuntime.AccessLevel(rawValue: method.accessLevel)!), isComputed: true, isStatic: method.isStatic, defaultValue: nil, attributes: [:], annotations: convertionAnnotations, definedInTypeName: method.definedInTypeName)
        }
    }
}

extension Type {
    var virtualPropertyDecls: [String] {
        let virtualProps: [String] = self.annotations.filter { $0.key.contains("virtualProp") }.map { $0.value as? String ?? "" }
        return virtualProps
    }
}
