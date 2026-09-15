import Foundation

enum DevicePatchService {
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        let bundleIDs = orderedBundleIdentifiers(in: project)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.apply(
                project: project,
                backupRoot: try PatchProjectLibrary.backupRootURL(),
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func inspectRestore(receipt: PatchTransactionReceipt) throws -> PatchRestoreInspection {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.inspectRestore(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func restore(
        receipt: PatchTransactionReceipt,
        allowChangedTargets: Bool = false
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.restore(
                receipt: receipt,
                allowChangedTargets: allowChangedTargets,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func resetToAppliedState(
        receipt: PatchTransactionReceipt,
        project: PatchProject
    ) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.resetToAppliedState(
                receipt: receipt,
                fallbackProject: project,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        var roots: [String: URL] = [:]

        for bundleID in bundleIDs {
            // Tentativa 1: MCM + metadata scan (caminho normal)
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID),
               ContainerStore.isApplicationContainerPath(path) {
                roots[bundleID] = PatchPathValidator.canonicalFileURL(
                    URL(fileURLWithPath: path, isDirectory: true)
                )
                continue
            }

            // Tentativa 2: scan direto pelo filesystem sem exigir sandbox escape
            // Util no iOS 27 onde o MCM pode recusar mas leitura direta funciona
            let allDirs = ContainerStore.enumerateDirectoriesWithTraversalGrant(
                path: ContainerStore.appDataRoot
            )

            var found = false
            for dir in allDirs {
                guard UUID(uuidString: (dir as NSString).lastPathComponent) != nil else { continue }

                // Tenta ler metadata diretamente
                if let metadata = ContainerStore.readContainerMetadata(containerPath: dir),
                   metadata.bundleID == bundleID,
                   ContainerStore.isApplicationContainerPath(dir) {
                    log("patch: filesystem scan resolved \(bundleID) -> \(dir)")
                    roots[bundleID] = PatchPathValidator.canonicalFileURL(
                        URL(fileURLWithPath: dir, isDirectory: true)
                    )
                    found = true
                    break
                }
            }

            if !found {
                // Tentativa 3: bad_query com create=true para forçar acesso
                var bundleIDC = bundleID.utf8CString.map { Int8($0) }
                let handle = bad_query(&bundleIDC, true, nil, false)
                if handle >= 0 {
                    bad_query_release(handle)
                    // Tenta novamente após o grant
                    if let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID),
                       ContainerStore.isApplicationContainerPath(path) {
                        log("patch: bad_query grant resolved \(bundleID)")
                        roots[bundleID] = PatchPathValidator.canonicalFileURL(
                            URL(fileURLWithPath: path, isDirectory: true)
                        )
                        found = true
                    }
                }
            }

            if !found {
                log("patch: FAILED to resolve container for \(bundleID)")
                throw PatchPackageError.targetAppUnavailable(bundleID)
            }
        }
        return try operation(roots)
    }
}
