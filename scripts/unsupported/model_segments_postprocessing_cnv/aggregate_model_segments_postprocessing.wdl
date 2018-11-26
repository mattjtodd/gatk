# Unsupported workflow that concatenates the IGV compatible files generated by multiple runs of model_segments_postprocessing.wdl
workflow AggregateModelSegmentsPostProcessingWorkflow {
    String group_id
    Array[File] tumor_with_germline_filtered_segs
    Array[File] normals_igv_compat
    Array[File] tumors_igv_compat
    Array[File] tumors_gistic2_compat

    call TsvCat as TsvCatTumorGermlineFiltered {
        input:
            input_files = tumor_with_germline_filtered_segs,
            id = group_id + "_TumorGermlineFiltered"
    }

    call TsvCatNoHeader as TsvCatTumorGermlineFilteredGistic2 {
        input:
            input_files = tumors_gistic2_compat,
            id = group_id + "_TumorGermlineFilteredGistic2"
    }

    call TsvCat as TsvCatTumor {
            input:
                input_files = tumors_igv_compat,
                id = group_id + "_Tumor"
    }

    call TsvCat as TsvCatNormal {
            input:
                input_files = normals_igv_compat,
                id = group_id + "_Normal"
    }

    output {
        File cnv_postprocessing_aggregated_tumors_pre = TsvCatTumor.aggregated_tsv
        File cnv_postprocessing_aggregated_tumors_post = TsvCatTumorGermlineFiltered.aggregated_tsv
        File cnv_postprocessing_aggregated_tumors_post_gistic2 = TsvCatTumorGermlineFilteredGistic2.aggregated_tsv
        File cnv_postprocessing_aggregated_normals = TsvCatNormal.aggregated_tsv
    }
}


task TsvCat {

	String id
	Array[File] input_files

	command <<<
    set -e

    head -1 ${input_files[0]} > ${id}.aggregated.seg

    for FILE in ${sep=" " input_files}
    do
        egrep -v "CONTIG|Chromosome" $FILE >> ${id}.aggregated.seg
    done
	>>>

	output {
		File aggregated_tsv="${id}.aggregated.seg"
	}

	runtime {
		docker: "ubuntu:16.04"
		memory: "2 GB"
		cpu: "1"
		disks: "local-disk 100 HDD"
	}
}

task TsvCatNoHeader {

	String id
	Array[File] input_files

	command <<<
    set -e

    for FILE in ${sep=" " input_files}
    do
        cat $FILE >> ${id}.aggregated.seg
    done
	>>>

	output {
		File aggregated_tsv="${id}.aggregated.seg"
	}

	runtime {
		docker: "ubuntu:16.04"
		memory: "2 GB"
        cpu: "1"
		disks: "local-disk 100 HDD"
	}
}