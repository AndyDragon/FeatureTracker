//
//  MigrationPlan.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-12-23.
//

import SwiftData
import SwiftUI

enum FeatureTrackerSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            migrateV1toV2
        ]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            var pages = try? context.fetch(FetchDescriptor<SchemaV1.Page>())
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
                    print("Found page \(page.name) with \(pagesWithId.count - 1) duplicates")
                    pagesWithId.forEach { otherPage in
                        if page == otherPage {
                            // same page, ignore this one
                            print("Skipping 'same page'")
                            return
                        }
                        if page.name != otherPage.name || page.isChallenge != otherPage.isChallenge {
                            // this is a different page, just set new ID
                            if !pagesForNewId.contains(otherPage) {
                                print("Found different page \(otherPage.name), changing ID")
                                pagesForNewId.append(otherPage)
                            }
                        } else {
                            // this is a duplicate of the same page, we need to merge the features and remove the duplicate
                            print("Found duplicate page \(otherPage.name), merging and deleting the duplicates")
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
                var featuresForNewId = [SchemaV1.Feature]()
                var featuresToDelete = [SchemaV1.Feature]()
                page.features?.forEach { feature in
                    if featuresForNewId.contains(feature) {
                        // Already marked for deletion
                        return
                    }
                    let featuresWithId = page.features?.filter { $0.id == feature.id } ?? []
                    if featuresWithId.count > 1 {
                        // There were duplicate IDs, now the fun begins again...
                        print("Found page \(page.name) with feature \(feature.notes) with \(featuresWithId.count - 1) duplicates")
                        featuresWithId.forEach { otherFeature in
                            if feature == otherFeature {
                                // same feature, ignore this one
                                print("Skipping 'same feature'")
                                return
                            }
                            if feature.notes != otherFeature.notes || feature.date != otherFeature.date {
                                // this is a different feature, just set new ID
                                print("Found different feature \(otherFeature.notes), changing ID")
                                featuresForNewId.append(otherFeature)
                            } else {
                                // this is a duplicate of the same feature, we will remove the duplicate
                                print("Found duplicate feature \(otherFeature.notes), deleting duplicate")
                                featuresToDelete.append(otherFeature)
                            }
                        }
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
        },
        didMigrate: nil)
}

