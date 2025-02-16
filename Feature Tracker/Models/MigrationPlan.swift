//
//  MigrationPlan.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-12-23.
//

import SwiftData
import SwiftUI
import SwiftyBeaver

enum FeatureTrackerSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self,
            SchemaV3.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            migrateV1toV2,
            migrateV2toV3
        ]
    }

    // This migration deduplicates pages and features with non-unique IDs for Schema V2:
    //  For each page
    //      For each page with duplicate id
    //          Check if the page has the same name and is challenge flag
    //              Merge the features and delete the other page
    //          Otherwise, the other page needs a new ID
    //      Check if the given page's ID is not unique across all ID's used so far
    //          The page needs a new ID
    //      For each feature on page
    //          For reach feature with duplicate id
    //              Check if the page has the same notes
    //                  Duplicate feature, delete the other feature
    //              Otherwise, the other feature needs a new ID
    //          Check if the given feature's ID is not unique across all ID's used so far
    //              The feature needs a new ID
    //  Save the results
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            SwiftyBeaver.self.info("Running migration state V1 to V2...", context: "Data")
            var pages = try? context.fetch(FetchDescriptor<SchemaV1.Page>())
            var idUsed = Set<UUID>()

            // Check for pages with duplicate IDs
            var pagesForNewId = [SchemaV1.Page]()
            var pagesToDelete = [SchemaV1.Page]()
            pages?.forEach { page in
                if pagesToDelete.contains(page) {
                    // Already marked for deletion
                    return
                }
                let pagesWithId = pages?.filter { $0.id == page.id } ?? []
                if pagesWithId.count > 1 {
                    // There were duplicate IDs, now the fun begins...
                    SwiftyBeaver.self.info("Found page \(page.name) with \(pagesWithId.count - 1) duplicates", context: "Data")
                    pagesWithId.forEach { otherPage in
                        if page == otherPage {
                            // same page, ignore this one
                            SwiftyBeaver.self.info("Skipping 'same page'")
                            return
                        }
                        if page.name != otherPage.name || page.isChallenge != otherPage.isChallenge {
                            // this is a different page, just set new ID
                            if !pagesForNewId.contains(otherPage) {
                                SwiftyBeaver.self.info("Found different page \(otherPage.name), changing ID", context: "Data")
                                pagesForNewId.append(otherPage)
                            }
                        } else {
                            // this is a duplicate of the same page, we need to merge the features and remove the duplicate
                            SwiftyBeaver.self.info("Found duplicate page \(otherPage.name), merging and deleting the duplicates", context: "Data")
                            if !pagesToDelete.contains(otherPage) {
                                pagesToDelete.append(otherPage)
                                otherPage.features?.forEach { otherFeature in
                                    if page.features == nil {
                                        page.features = [SchemaV1.Feature]()
                                    }
                                    page.features!.append(otherFeature)
                                }
                            }
                        }
                    }
                }

                // Check for page id already used
                if idUsed.contains(page.id) {
                    if !pagesForNewId.contains(page) {
                        SwiftyBeaver.self.info("Found page with used id \(page.name), changing ID", context: "Data")
                        pagesForNewId.append(page)
                    }
                } else {
                    idUsed.insert(page.id)
                }

                // Check for features with duplicate IDs in the page
                var featuresForNewId = [SchemaV1.Feature]()
                var featuresToDelete = [SchemaV1.Feature]()
                page.features?.forEach { feature in
                    if featuresToDelete.contains(feature) {
                        // Already marked for deletion
                        return
                    }
                    let featuresWithId = page.features?.filter { $0.id == feature.id } ?? []
                    if featuresWithId.count > 1 {
                        // There were duplicate IDs, now the fun begins again...
                        SwiftyBeaver.self.info("Found page \(page.name) with feature \(feature.notes) with \(featuresWithId.count - 1) duplicates", context: "Data")
                        featuresWithId.forEach { otherFeature in
                            if feature == otherFeature {
                                // same feature, ignore this one
                                SwiftyBeaver.self.info("Skipping 'same feature'")
                                return
                            }
                            if feature.notes != otherFeature.notes || feature.date != otherFeature.date {
                                // this is a different feature, just set new ID
                                SwiftyBeaver.self.info("Found different feature \(otherFeature.notes), changing ID", context: "Data")
                                featuresForNewId.append(otherFeature)
                            } else {
                                // this is a duplicate of the same feature, we will remove the duplicate
                                SwiftyBeaver.self.info("Found duplicate feature \(otherFeature.notes), deleting duplicate", context: "Data")
                                featuresToDelete.append(otherFeature)
                            }
                        }
                    }

                    // Check for feature id already used
                    if idUsed.contains(feature.id) {
                        if !featuresForNewId.contains(feature) {
                            SwiftyBeaver.self.info("Found feature with used id \(feature.notes), changing ID", context: "Data")
                            featuresForNewId.append(feature)
                        }
                    } else {
                        idUsed.insert(feature.id)
                    }
                }

                // Apply new IF for different features in the page
                featuresForNewId.forEach { featureForNewId in
                    featureForNewId.id = UUID()
                }
                // Clean up the duplicate features in the page
                featuresToDelete.forEach { featureToDelete in
                    page.features?.remove(element: featureToDelete)
                    context.delete(featureToDelete)
                }
            }

            // Apply new ID for different pages
            pagesForNewId.forEach { pageForNewId in
                pageForNewId.id = UUID()
            }
            // Clean up the duplicate pages
            pagesToDelete.forEach { pageToDelete in
                context.delete(pageToDelete)
            }

            // Save the updated DB
            try context.save()
            SwiftyBeaver.self.info("Completed migration state V1 to V2...", context: "Data")
        },
        didMigrate: nil)

    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            SwiftyBeaver.self.info("Running migration state V2 to V3...", context: "Data")
            var pages = try? context.fetch(FetchDescriptor<SchemaV3.Page>())
            var idUsed = Set<UUID>()

            // Check for pages with missing hubs
            pages?.forEach { page in
                if page.hub.isEmpty {
                    page.hub = "snap"
                }
            }

            // Save the updated DB
            try context.save()
            SwiftyBeaver.self.info("Completed migration state V2 to V3...", context: "Data")
        })
}

extension SchemaV3 {
    static func collatePages(_ sourcePages: [Page]?) -> [Page] {
        SwiftyBeaver.self.info("Running page collation process...", context: "Data")
        var idUsed = Set<UUID>()

        var pages = sourcePages?.map({ $0 }) ?? []

        // Check for pages with duplicate IDs
        var pagesForNewId = [Page]()
        var pagesToDelete = [Page]()
        pages.forEach { page in
            if pagesToDelete.contains(page) {
                // Already marked for deletion
                return
            }
            let pagesWithId = pages.filter { $0.id == page.id }
            if pagesWithId.count > 1 {
                // There were duplicate IDs, now the fun begins...
                SwiftyBeaver.self.info("Found page \(page.name) with \(pagesWithId.count - 1) duplicates", context: "Data")
                pagesWithId.forEach { otherPage in
                    if page == otherPage {
                        // same page, ignore this one
                        SwiftyBeaver.self.info("Skipping 'same page'")
                        return
                    }
                    if page.name != otherPage.name || page.isChallenge != otherPage.isChallenge {
                        // this is a different page, just set new ID
                        if !pagesForNewId.contains(otherPage) {
                            SwiftyBeaver.self.info("Found different page \(otherPage.name), changing ID", context: "Data")
                            pagesForNewId.append(otherPage)
                        }
                    } else {
                        // this is a duplicate of the same page, we need to merge the features and remove the duplicate
                        SwiftyBeaver.self.info("Found duplicate page \(otherPage.name), merging and deleting the duplicates", context: "Data")
                        if !pagesToDelete.contains(otherPage) {
                            pagesToDelete.append(otherPage)
                            otherPage.features?.forEach { otherFeature in
                                if page.features == nil {
                                    page.features = [Feature]()
                                }
                                page.features!.append(otherFeature)
                            }
                        }
                    }
                }
            }

            // Check for page id already used
            if idUsed.contains(page.id) {
                if !pagesForNewId.contains(page) {
                    SwiftyBeaver.self.info("Found page with used id \(page.name), changing ID", context: "Data")
                    pagesForNewId.append(page)
                }
            } else {
                idUsed.insert(page.id)
            }

            // Check for features with duplicate IDs in the page
            var featuresForNewId = [Feature]()
            var featuresToDelete = [Feature]()
            page.features?.forEach { feature in
                if featuresToDelete.contains(feature) {
                    // Already marked for deletion
                    return
                }
                let featuresWithId = page.features?.filter { $0.id == feature.id } ?? []
                if featuresWithId.count > 1 {
                    // There were duplicate IDs, now the fun begins again...
                    SwiftyBeaver.self.info("Found page \(page.name) with feature \(feature.notes) with \(featuresWithId.count - 1) duplicates", context: "Data")
                    featuresWithId.forEach { otherFeature in
                        if feature == otherFeature {
                            // same feature, ignore this one
                            SwiftyBeaver.self.info("Skipping 'same feature'")
                            return
                        }
                        if feature.notes != otherFeature.notes || feature.date != otherFeature.date {
                            // this is a different feature, just set new ID
                            SwiftyBeaver.self.info("Found different feature \(otherFeature.notes), changing ID", context: "Data")
                            featuresForNewId.append(otherFeature)
                        } else {
                            // this is a duplicate of the same feature, we will remove the duplicate
                            SwiftyBeaver.self.info("Found duplicate feature \(otherFeature.notes), deleting duplicate", context: "Data")
                            featuresToDelete.append(otherFeature)
                        }
                    }
                }

                // Check for feature id already used
                if idUsed.contains(feature.id) {
                    if !featuresForNewId.contains(feature) {
                        SwiftyBeaver.self.info("Found feature with used id \(feature.notes), changing ID", context: "Data")
                        featuresForNewId.append(feature)
                    }
                } else {
                    idUsed.insert(feature.id)
                }
            }

            // Apply new IF for different features in the page
            featuresForNewId.forEach { featureForNewId in
                featureForNewId.id = UUID()
            }
            // Clean up the duplicate features in the page
            featuresToDelete.forEach { featureToDelete in
                page.features?.remove(element: featureToDelete)
            }
        }

        // Apply new ID for different pages
        pagesForNewId.forEach { pageForNewId in
            pageForNewId.id = UUID()
        }
        // Clean up the duplicate pages
        pagesToDelete.forEach { pageToDelete in
            pages.remove(element: pageToDelete)
        }

        return pages
    }
}
