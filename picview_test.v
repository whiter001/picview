module picview

import os

fn test_natural_compare_orders_numbers_numerically() {
	mut files := ['img10.jpg', 'img2.jpg', 'img1.jpg', 'img10a.jpg', 'a.png', 'B.png']
	files.sort_with_compare(natural_compare)
	assert files == ['B.png', 'a.png', 'img1.jpg', 'img2.jpg', 'img10.jpg', 'img10a.jpg']
}

fn test_natural_compare_leading_zeros() {
	p1 := 'img01.jpg'
	p2 := 'img1.jpg'
	p3 := 'img02.jpg'
	p4 := 'img2.jpg'
	assert natural_compare(p1, p2) == 0
	assert natural_compare(p3, p2) == 1
	assert natural_compare(p2, p4) == -1
}

fn test_collect_images_recursive() {
	root := os.join_path(os.temp_dir(), 'picview_test_collect_images')
	os.mkdir_all(os.join_path(root, 'sub')) or { panic(err) }
	os.write_file(os.join_path(root, 'a.jpg'), '') or { panic(err) }
	os.write_file(os.join_path(root, 'b.txt'), '') or { panic(err) }
	os.write_file(os.join_path(root, 'sub', 'c.png'), '') or { panic(err) }
	defer {
		os.rmdir_all(root) or {}
	}
	flat := collect_images(root, false)
	assert flat.len == 1
	assert flat[0].ends_with('a.jpg')
	recursive := collect_images(root, true)
	assert recursive.len == 2
}
